import { initializeApp, getApp, getApps, cert } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

function escapeHtml(str) {
  return String(str || '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function resolveMediaUrl(mediaUrl, mediaType) {
  if (!mediaUrl) return null;
  const driveMatch = mediaUrl.match(/\/file\/d\/([a-zA-Z0-9_-]+)/) || mediaUrl.match(/id=([a-zA-Z0-9_-]+)/);
  if (driveMatch && driveMatch[1]) {
    return mediaType === 'video'
      ? `https://drive.google.com/uc?export=download&id=${driveMatch[1]}`
      : `https://lh3.googleusercontent.com/d/${driveMatch[1]}`;
  }
  return mediaUrl;
}

function extractYoutubeId(url) {
  if (!url) return null;
  const match = url.match(/(?:youtube\.com\/(?:watch\?v=|embed\/|shorts\/)|youtu\.be\/)([a-zA-Z0-9_-]{11})/);
  return match ? match[1] : null;
}

export default async function handler(req, res) {
  const postId = req.query.postId || req.query.id || '';
  const FALLBACK_IMAGE = 'https://dreams-casino-app.web.app/presentacion_dreams_club.jpg';

  let title = 'Publicación Compartida';
  let description = 'Mira esta publicación de Casinos Dreams en la app oficial DreamsClub.';
  let ogImage = FALLBACK_IMAGE;
  let ogVideoUrl = null;

  if (postId) {
    try {
      if (getApps().length === 0) {
        const privateKey = process.env.FIREBASE_PRIVATE_KEY
          ? process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n')
          : undefined;
        initializeApp({
          credential: cert({
            projectId: process.env.FIREBASE_PROJECT_ID,
            clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
            privateKey: privateKey,
          }),
        });
      }
      const app = getApp();
      const snap = await getFirestore(app).collection('posts').doc(postId).get();
      if (snap.exists) {
        const post = snap.data();
        title = post.title || title;
        description = post.description || description;

        const youtubeId = post.mediaType === 'video' ? extractYoutubeId(post.mediaUrl) : null;
        if (youtubeId) {
          ogImage = `https://img.youtube.com/vi/${youtubeId}/hqdefault.jpg`;
        } else if (post.mediaType === 'video') {
          // Video no-YouTube: mostrar miniatura si existe, si no la imagen genérica
          ogImage = post.thumbnailUrl ? resolveMediaUrl(post.thumbnailUrl, 'image') : FALLBACK_IMAGE;
          ogVideoUrl = resolveMediaUrl(post.mediaUrl, 'video');
        } else if (post.mediaUrl) {
          ogImage = resolveMediaUrl(post.mediaUrl, 'image');
        }
      }
    } catch (err) {
      console.error('Error fetching post for share preview:', err);
    }
  }

  const safeTitle = escapeHtml(title);
  const safeDescription = escapeHtml(description);
  const shareUrl = `https://dreams-casino-app.web.app/share${postId ? `?postId=${encodeURIComponent(postId)}` : ''}`;
  const appSchemeUrl = postId ? `dreamsclub://post/${postId}` : 'dreamsclub://home';
  const apkUrl = 'https://github.com/shaklinedj/DreamsClub-Release/releases/download/v1.0.8/app-arm64-v8a-release.apk';

  const html = `<!DOCTYPE html>
<html lang="es" class="dark">
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>${safeTitle} - DreamsClub</title>
    <meta name="description" content="${safeDescription}" />

    <meta property="og:title" content="${safeTitle}" />
    <meta property="og:description" content="${safeDescription}" />
    <meta property="og:type" content="article" />
    <meta property="og:image" content="${ogImage}" />
    <meta property="og:image:width" content="1200" />
    <meta property="og:image:height" content="630" />
    <meta property="og:url" content="${shareUrl}" />
    ${ogVideoUrl ? `<meta property="og:video" content="${ogVideoUrl}" />\n    <meta property="og:video:type" content="video/mp4" />` : ''}
    <meta name="twitter:card" content="summary_large_image" />
    <meta name="twitter:image" content="${ogImage}" />

    <link rel="icon" type="image/svg+xml" href="https://dreams-casino-app.web.app/favicon.svg" />
    <style>
        body { margin:0; font-family: 'Plus Jakarta Sans', sans-serif; background:#0b0f19; color:#f1f5f9; min-height:100vh; display:flex; align-items:center; justify-content:center; }
        .card { max-width:420px; width:90%; background:rgba(15,23,42,0.9); border:1px solid rgba(51,65,85,0.8); border-radius:24px; padding:32px; text-align:center; }
        img, video { width:100%; border-radius:16px; margin-top:16px; max-height:280px; object-fit:cover; }
        a.btn { display:inline-flex; align-items:center; justify-content:center; gap:8px; width:100%; padding:14px; border-radius:16px; font-weight:800; text-decoration:none; margin-top:12px; }
        .primary { background:linear-gradient(90deg,#7c3aed,#4f46e5); color:#fff; }
        .secondary { background:rgba(245,158,11,0.15); color:#fbbf24; border:1px solid rgba(245,158,11,0.3); }
    </style>
</head>
<body>
    <div class="card">
        <h1>${safeTitle}</h1>
        <p>${safeDescription}</p>
        ${ogVideoUrl ? `<video src="${ogVideoUrl}" controls></video>` : `<img src="${ogImage}" alt="Preview" />`}
        <a class="btn primary" id="openAppBtn" href="${appSchemeUrl}">🚀 Abrir en DreamsClub App</a>
        <a class="btn secondary" href="${apkUrl}">⬇️ No tengo la app (Descargar APK)</a>
    </div>
    <script>
        (function() {
            var isMobile = /Android|iPhone|iPad|iPod/i.test(navigator.userAgent);
            if (isMobile) {
                setTimeout(function() {
                    window.location.href = ${JSON.stringify(appSchemeUrl)};
                }, 600);
            }
        })();
    </script>
</body>
</html>`;

  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.setHeader('Cache-Control', 'public, max-age=300, s-maxage=300');
  return res.status(200).send(html);
}
