import { takeSharedText } from "../share_target";

const buildContent = ({ text, url }) => {
  if (url && !text.includes(url)) return [text, url].filter(Boolean).join("\n");
  return text;
};

const BinShare = {
  async mounted() {
    const shared = await takeSharedText();
    if (!shared) return;

    const title = document.getElementById("paste_title");
    const content = document.getElementById("paste_content");

    title.value = shared.title || "Shared";
    content.value = buildContent(shared);
    content.dispatchEvent(new Event("input", { bubbles: true }));
  },
};

export default BinShare;
