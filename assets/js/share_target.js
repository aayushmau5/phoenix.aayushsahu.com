const SHARE_CACHE = "share-target";

const openShareCache = () =>
  "caches" in window ? caches.open(SHARE_CACHE) : Promise.resolve(null);

const clearSharedParam = () => {
  const url = new URL(window.location.href);
  if (!url.searchParams.has("shared")) return;
  url.searchParams.delete("shared");
  window.history.replaceState(window.history.state, "", url);
};

export const registerServiceWorker = () => {
  if (!("serviceWorker" in navigator)) return;

  window.addEventListener("load", () => {
    navigator.serviceWorker.register("/sw.js").catch((error) => {
      console.error("Service worker registration failed", error);
    });
  });
};

export const takeSharedPhotos = async () => {
  clearSharedParam();
  const cache = await openShareCache();
  if (!cache) return [];

  const keys = (await cache.keys()).filter((request) =>
    new URL(request.url).pathname.startsWith("/shared/photos/"),
  );

  const files = await Promise.all(
    keys.map(async (request) => {
      const response = await cache.match(request);
      const blob = await response.blob();
      const name = decodeURIComponent(
        response.headers.get("x-file-name") || "shared-photo",
      );
      await cache.delete(request);
      return new File([blob], name, { type: blob.type });
    }),
  );

  return files;
};

export const takeSharedText = async () => {
  clearSharedParam();
  const cache = await openShareCache();
  if (!cache) return null;

  const response = await cache.match("/shared/text");
  if (!response) return null;

  await cache.delete("/shared/text");
  return response.json();
};
