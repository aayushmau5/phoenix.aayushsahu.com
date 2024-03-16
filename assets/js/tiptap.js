import { Editor } from "@tiptap/core";
import StarterKit from "@tiptap/starter-kit";

export function createEditor() {
	return new Editor({
		element: document.querySelector("#editor"),
		extensions: [
			StarterKit,
		],
		content: '<p>Hello World!</p>',
	});
}

export function createHook() {
	return {
		mounted() {
			console.log("hook called")
			createEditor();
		}
	}
}
