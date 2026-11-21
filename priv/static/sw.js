const SHARE_CACHE = "share-target";

self.addEventListener("install", () => self.skipWaiting());

self.addEventListener("activate", (event) => {
  event.waitUntil(self.clients.claim());
});

self.addEventListener("fetch", (event) => {
  const url = new URL(event.request.url);

  if (event.request.method === "POST" && url.pathname === "/share") {
    event.respondWith(handleShare(event.request));
  }
});

async function handleShare(request) {
  const data = await request.formData();
  const cache = await caches.open(SHARE_CACHE);

  const oldKeys = await cache.keys();
  await Promise.all(oldKeys.map((key) => cache.delete(key)));

  const photos = data
    .getAll("photos")
    .filter((file) => file instanceof File && file.size > 0);

  if (photos.length > 0) {
    await Promise.all(
      photos.map((file, index) =>
        cache.put(
          `/shared/photos/${index}`,
          new Response(file, {
            headers: {
              "content-type": file.type,
              "x-file-name": encodeURIComponent(file.name),
            },
          }),
        ),
      ),
    );

    return Response.redirect("/photos?shared=1", 303);
  }

  await cache.put(
    "/shared/text",
    Response.json({
      title: data.get("title") || "",
      text: data.get("text") || "",
      url: data.get("url") || "",
    }),
  );

  return Response.redirect("/bin/create?shared=1", 303);
}
