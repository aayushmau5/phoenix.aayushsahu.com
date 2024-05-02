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
		this.handleEvent("new-note-scroll", () => this.el.scrollTo(0, this.el.scrollHeight));
		this.el.scrollTo(0, this.el.scrollHeight);
	}
}

// For notes
Hooks.NotesInput = {
	mounted() {
		this.el.addEventListener("keydown", this.handleKeyDown);
	},
	handleKeyDown(event) {
		const isMobile = /iPhone|iPad|iPod|Android/i.test(navigator.userAgent);
		if (!isMobile && event.key === "Enter" && !event.shiftKey) {
			const notesForm = document.getElementById("notes-form");
			notesForm.dispatchEvent(
				new Event("submit", { bubbles: true, cancelable: true })
			)
		}
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

