// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import topbar from "../vendor/topbar"

const Hooks = {};

Hooks.LocalTime = {
	mounted() {
		this.updated()
	},
	updated() {
		const dt = new Date(this.el.textContent);
		this.el.textContent = dt.toLocaleString();
		this.el.classList.remove("invisible")
	}
}

// For notes
Hooks.ScrollToBottom = {
	mounted() {
		this.handleEvent("new-note-scroll", (payload) => {
			// Check if this is a submission event
			if (payload.submitted) {
				this.scrollToBottom();
			}
		});
		// Store last content length to detect actual content changes vs typing
		this.lastContentLength = this.getContentLength();
		// Always scroll to bottom when component is mounted
		setTimeout(() => this.scrollToBottom(), 100);
	},
	updated() {
		// Only scroll if explicitly told to (via event)
		// Don't auto-scroll on every update to prevent scrolling while typing
	},
	scrollToBottom() {
		// Find the parent scrollable container
		const scrollContainer = this.el.closest('.overflow-y-auto');
		if (scrollContainer) {
			scrollContainer.scrollTo({
				top: scrollContainer.scrollHeight,
				behavior: 'smooth'
			});
		} else {
			this.el.scrollTo({
				top: this.el.scrollHeight,
				behavior: 'smooth'
			});
		}
	},
	getContentLength() {
		// Helper to measure total content "size"
		return this.el.textContent.length;
	}
}

// For notes
Hooks.NotesInput = {
	mounted() {
		this.el.addEventListener("keydown", this.handleKeyDown);
		this.el.addEventListener("input", this.autoResize.bind(this));
		// Initial resize
		this.autoResize();
	},
	handleKeyDown(event) {
		const isMobile = /iPhone|iPad|iPod|Android/i.test(navigator.userAgent);
		if (!isMobile && event.key === "Enter" && !event.shiftKey) {
			const notesForm = document.getElementById("notes-form");
			notesForm.dispatchEvent(
				new Event("submit", { bubbles: true, cancelable: true })
			)
		}
		// Auto resize on key events like backspace/delete that might not trigger input event
		this.autoResize();
	},
	autoResize() {
		// Reset height to calculate scroll height correctly
		this.el.style.height = 'auto';
		
		// Get the maximum height (max-h-[150px] converted to pixels)
		const maxHeight = 150;
		
		// Calculate content height
		const contentHeight = this.el.scrollHeight;
		
		// Set height based on content but capped at max height
		if (contentHeight <= maxHeight) {
			// Content fits within max height - grow normally
			this.el.style.height = contentHeight + 'px';
			this.el.style.overflowY = 'hidden';
		} else {
			// Content exceeds max height - enable scrolling
			this.el.style.height = maxHeight + 'px';
			this.el.style.overflowY = 'auto';
			
			// Ensure cursor is visible by scrolling to bottom when typing
			if (this.el === document.activeElement) {
				this.el.scrollTop = contentHeight;
			}
		}
	},
	updated() {
		// Ensure proper sizing after LiveView updates
		this.autoResize();
	}
}

Hooks.MaintainAttrs = {
	attrs() { return this.el.getAttribute("data-attrs").split(", ") },
	beforeUpdate() { this.prevAttrs = this.attrs().map(name => [name, this.el.getAttribute(name)]) },
	updated() { this.prevAttrs.forEach(([name, val]) => this.el.setAttribute(name, val)) }
}

window.addEventListener("phx:copy", (event) => {
	const text = event.target.innerText;
	navigator.clipboard.writeText(text).then(() => {
		const copyButtonTextEl = document.getElementById("copy-button-text");
		copyButtonTextEl.innerText = "Copied!";
		setTimeout(() => {
			copyButtonTextEl.innerText = "Copy";
		}, 1000);
	})
})

window.addEventListener("phx:notes-workspace-modal", ({ detail }) => {
	// https://fly.io/phoenix-files/server-triggered-js/
	const modalId = detail.modal_id;
	const modalEl = document.getElementById(modalId);
	window.liveSocket.execJS(modalEl, modalEl.getAttribute(detail.attr));
})

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, { hooks: Hooks, params: { _csrf_token: csrfToken } })

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#00C6C2" }, shadowColor: "rgba(0, 0, 0, .3)" })
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

