# Feed — code examples

**Contract (ARIA, states, keyboard, RAWeb criteria):** run
`scripts/raweb-component-lookup.sh show feed`

---

## The infinite scroll problem

This is the pattern's defining issue, and it's a **RAWeb 12.9** failure:

> If content loads forever as you scroll, **the footer is unreachable**. A
> keyboard user Tabs toward it and more content keeps appearing between them and
> their destination. They can never arrive.

Screen reader users hit the same wall. So does anyone using "find in page" to
reach the privacy link. Auto-loading on scroll *creates* a keyboard trap out of
nothing but eagerness.

**A "Load more" button fixes it completely.** The user decides when more content
exists; the footer stays reachable; there's nothing to trap anyone.

| What you have | Use |
|---|---|
| A list of posts, paginated or "Load more" | **`<ul>` of `<article>`s + a button** — no `role="feed"` |
| Auto-loading stream where reading position must survive updates | **feed** (this file) |
| A static list | just a list |

> `role="feed"` exists for a genuine *stream* — where the browser's normal
> scroll/focus model isn't enough because content arrives while you read. That
> is rarer than it looks.

---

## Universal rules

- **Prefer a plain list plus a "Load more" button.** Simpler, keyboard-safe,
  footer reachable. (RAWeb 12.9)
- **`aria-busy="true"` while inserting, `false` when done.** Otherwise assistive
  technologies read a half-built DOM.
- **Every article needs a heading**, with `aria-labelledby` pointing at it. Feeds
  are navigated *by heading*. (RAWeb 9.1)
- **`aria-posinset` + `aria-setsize` on each article.** Use `aria-setsize="-1"`
  when the total is unknown — that's what it's for.
- **Announce loading in a *separate* polite live region.** Never `aria-live` on
  the feed itself: that announces every inserted article. (RAWeb 7.5)
- **Never move focus when new items load.** The user is reading.
- **Auto-refreshing feeds must be pausable.** (RAWeb 13.8)

---

## Vanilla

### Do — the version you probably want

```html
<h1>Latest posts</h1>

<!-- No role="feed". A list of articles and an explicit button. The footer stays
     reachable, and there is nothing to get wrong (RAWeb 12.9). -->
<ul class="posts">
  <li>
    <article aria-labelledby="post-1-title">
      <h2 id="post-1-title"><a href="/posts/1">RAWeb 1.1 released</a></h2>
      <p>The new version adds 17 criteria…</p>
    </article>
  </li>
</ul>

<button type="button" id="load-more">Load more posts</button>

<!-- Separate live region — NOT aria-live on the list (RAWeb 7.5). -->
<div id="posts-status" role="status" aria-live="polite" class="sr-only"></div>

<footer>…reachable, always…</footer>
```

```js
const list = document.querySelector('.posts');
const loadMore = document.getElementById('load-more');
const status = document.getElementById('posts-status');

loadMore.addEventListener('click', async () => {
  loadMore.disabled = true;
  status.textContent = 'Loading more posts…';

  const posts = await fetchPosts();
  for (const post of posts) list.append(renderPost(post));

  loadMore.disabled = false;
  // RAWeb 7.5 — say what happened. Do NOT move focus; the user is reading.
  status.textContent = `${posts.length} more posts loaded.`;

  if (!hasMore()) {
    loadMore.hidden = true;
    status.textContent = 'All posts loaded.';
  }
});
```

### Do — a real feed

```html
<h1>Activity</h1>

<button type="button" id="feed-pause">Pause automatic updates</button>

<!-- aria-busy is managed in JS. No aria-live here — see the status region. -->
<div role="feed" aria-labelledby="activity-heading" aria-busy="false" id="activity-feed">
  <article
    role="article"
    aria-labelledby="item-1-title"
    aria-posinset="1"
    aria-setsize="-1"
    tabindex="0"
  >
    <h2 id="item-1-title">Alice commented on Riverside housing</h2>
    <p>"The east elevation needs another look."</p>
  </article>

  <article role="article" aria-labelledby="item-2-title" aria-posinset="2" aria-setsize="-1" tabindex="0">
    <h2 id="item-2-title">Bob uploaded 3 files</h2>
    <p>plans-v2.pdf, elevations.pdf, notes.md</p>
  </article>
</div>

<div id="feed-status" role="status" aria-live="polite" class="sr-only"></div>
```

`aria-setsize="-1"` is the correct value for "total unknown" — it tells the
screen reader to announce the position without claiming a total it can't know.

```css
[role="feed"] article:focus-visible {
  outline: 2px solid #0056b3;
  outline-offset: 2px;
}
```

```js
const feed = document.getElementById('activity-feed');
const status = document.getElementById('feed-status');
const pauseButton = document.getElementById('feed-pause');
let paused = false;
let timer = null;

const articles = () => [...feed.querySelectorAll('[role="article"]')];

// Page Down / Page Up move between articles — the feed keyboard model.
feed.addEventListener('keydown', (event) => {
  const current = event.target.closest('[role="article"]');
  if (!current) return;
  const items = articles();
  const index = items.indexOf(current);

  if (event.key === 'PageDown') { event.preventDefault(); items[index + 1]?.focus(); }
  else if (event.key === 'PageUp') { event.preventDefault(); items[index - 1]?.focus(); }
  else if (event.ctrlKey && event.key === 'Home') { event.preventDefault(); items[0]?.focus(); }
  else if (event.ctrlKey && event.key === 'End') { event.preventDefault(); items.at(-1)?.focus(); }
  // Tab: untouched.
});

async function loadMore() {
  // Tell AT the DOM is mid-change, so it does not read a half-built feed.
  feed.setAttribute('aria-busy', 'true');
  const items = await fetchActivity();
  const offset = articles().length;

  for (const [i, item] of items.entries()) {
    const article = renderArticle(item);
    article.setAttribute('aria-posinset', String(offset + i + 1));
    article.setAttribute('aria-setsize', '-1');   // total unknown
    feed.append(article);
  }

  feed.setAttribute('aria-busy', 'false');
  // Announced politely, without moving focus (RAWeb 7.5).
  status.textContent = `${items.length} new items.`;
}

// Auto-refresh must be pausable (RAWeb 13.8).
function play() {
  timer = setInterval(loadMore, 30000);
  pauseButton.textContent = 'Pause automatic updates';
}
function pause() {
  clearInterval(timer);
  timer = null;
  pauseButton.textContent = 'Resume automatic updates';
}
pauseButton.addEventListener('click', () => { paused = !paused; paused ? pause() : play(); });
play();
```

### Don't

```html
<!-- DON'T: auto-load on scroll with no end. THE feed failure.
     → The footer is unreachable, forever. A keyboard user Tabs toward the
       privacy link and more content keeps appearing in front of it. This is a
       keyboard trap built out of enthusiasm (RAWeb 12.9). -->
<div role="feed" data-infinite-scroll>…</div>

<!-- DON'T: aria-live on the feed.
     → Every inserted article is announced in full. Loading 20 posts reads 20
       posts aloud, over whatever the user was doing (RAWeb 7.5). -->
<div role="feed" aria-live="polite">…</div>

<!-- DON'T: articles with no heading.
     → Feeds are navigated BY HEADING. Without one there is no way to move
       through them (RAWeb 9.1), and aria-labelledby has nothing to point at. -->
<article role="article" tabindex="0">
  <p>Alice commented on Riverside housing</p>
</article>

<!-- DON'T: aria-setsize with an invented total.
     → Announces "1 of 20" in an infinite feed. Use -1 for unknown. -->
<article role="article" aria-posinset="1" aria-setsize="20">…</article>

<!-- DON'T: role="feed" on a static list.
     → Application-ish semantics and a Page Down model for a list that never
       changes. It is a <ul>. -->
<div role="feed">
  <article role="article">…</article>
</div>

<!-- DON'T: an unnamed feed. -->
<div role="feed">…</div>
```

```js
// DON'T: move focus to newly loaded content.
//     → The user is reading item 3. Twenty items load and focus jumps to item
//       24. They have lost their place completely, and nobody asked for this.
newArticles[0].focus();

// DON'T: skip aria-busy.
//     → Assistive technologies read the feed mid-insertion: half an article,
//       then a jump, then the rest.
for (const item of items) feed.append(renderArticle(item));

// DON'T: leave aria-busy="true" after an error.
//     → The feed is announced as permanently busy and users wait for content
//       that will never come. Always reset it in a finally.
try {
  feed.setAttribute('aria-busy', 'true');
  await fetchActivity();
  feed.setAttribute('aria-busy', 'false');
} catch { /* aria-busy stuck at true forever */ }
```

---

## React

### Do

```jsx
import { useEffect, useId, useRef, useState } from 'react';

export function PostList() {
  const [posts, setPosts] = useState([]);
  const [status, setStatus] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [hasMore, setHasMore] = useState(true);

  const loadMore = async () => {
    setIsLoading(true);
    setStatus('Loading more posts…');
    const next = await fetchPosts(posts.length);
    setPosts((p) => [...p, ...next]);
    setIsLoading(false);
    setHasMore(next.length > 0);
    setStatus(next.length ? `${next.length} more posts loaded.` : 'All posts loaded.');
  };

  return (
    <>
      <ul className="posts">
        {posts.map((post) => (
          <li key={post.id}>
            <Post post={post} />
          </li>
        ))}
      </ul>

      {/* An explicit button. The footer below stays reachable (RAWeb 12.9). */}
      {hasMore && (
        <button type="button" onClick={loadMore} disabled={isLoading}>
          {isLoading ? 'Loading…' : 'Load more posts'}
        </button>
      )}

      {/* Always mounted, empty when idle — see alert.md for why. */}
      <div role="status" aria-live="polite" className="sr-only">{status}</div>
    </>
  );
}

function Post({ post }) {
  const id = useId();
  return (
    <article aria-labelledby={id}>
      <h2 id={id}><a href={`/posts/${post.id}`}>{post.title}</a></h2>
      <p>{post.excerpt}</p>
    </article>
  );
}
```

### Don't

```jsx
// DON'T: IntersectionObserver auto-loading with no end.
//     → The classic React infinite scroll. The sentinel is always just below
//       the fold, so it fires forever and the footer is never reachable
//       (RAWeb 12.9). If you must, cap it and show a button after N pages.
useEffect(() => {
  const observer = new IntersectionObserver(([entry]) => {
    if (entry.isIntersecting) loadMore();
  });
  observer.observe(sentinelRef.current);
  return () => observer.disconnect();
}, [loadMore]);

// DON'T: conditionally render the live region.
//     → Created together with its text; nothing is announced. See alert.md.
{status && <div role="status">{status}</div>}

// DON'T: focus new content after loading.
//     → Yanks the user away from what they were reading.
useEffect(() => { newestRef.current?.focus(); }, [posts.length]);

// DON'T: aria-busy that can get stuck.
//     → A rejected fetch leaves the feed announced as busy forever. Reset in a
//       finally.
```

---

## Angular

### Do

```ts
import { Component, signal } from '@angular/core';

@Component({
  selector: 'app-post-list',
  template: `
    <ul class="posts">
      @for (post of posts(); track post.id) {
        <li>
          <article [attr.aria-labelledby]="'post-' + post.id + '-title'">
            <h2 [id]="'post-' + post.id + '-title'">
              <a [href]="'/posts/' + post.id">{{ post.title }}</a>
            </h2>
            <p>{{ post.excerpt }}</p>
          </article>
        </li>
      }
    </ul>

    @if (hasMore()) {
      <button type="button" [disabled]="isLoading()" (click)="loadMore()">
        {{ isLoading() ? 'Loading…' : 'Load more posts' }}
      </button>
    }

    <div role="status" aria-live="polite" class="sr-only">{{ status() }}</div>
  `,
})
export class PostListComponent {
  protected readonly posts = signal<Post[]>([]);
  protected readonly status = signal('');
  protected readonly isLoading = signal(false);
  protected readonly hasMore = signal(true);

  protected async loadMore(): Promise<void> {
    this.isLoading.set(true);
    this.status.set('Loading more posts…');
    try {
      const next = await this.fetchPosts(this.posts().length);
      this.posts.update((p) => [...p, ...next]);
      this.hasMore.set(next.length > 0);
      this.status.set(next.length ? `${next.length} more posts loaded.` : 'All posts loaded.');
    } finally {
      // finally: a failed request must not leave the UI stuck "loading".
      this.isLoading.set(false);
    }
  }

  private fetchPosts(offset: number): Promise<Post[]> { /* … */ return Promise.resolve([]); }
}
```

**Or use the CDK** for a real virtualised feed: `@angular/cdk/scrolling`
(`cdk-virtual-scroll-viewport`). Note it solves *rendering* performance, not the
12.9 problem — you still owe a reachable end.

### Don't

```html
<!-- DON'T: @if around the live region — nothing announces. See alert.md. -->
@if (status()) { <div role="status">{{ status() }}</div> }

<!-- DON'T: [attr.aria-busy]="isLoading()" with no error path.
     → A thrown request leaves aria-busy="true" forever. -->
```

---

## Web Component

### Do

```js
// Light DOM: the live region and the article headings must be in the document
// tree — heading navigation does not reach into shadow roots (see accordion.md),
// and live-region support across the boundary is unreliable (see alert.md).
// Both of this pattern's core mechanisms argue against shadow DOM.
class A11yFeed extends HTMLElement {
  #feed;
  #status;

  connectedCallback() {
    this.#feed = this.querySelector('[role="feed"]');
    this.#status = this.querySelector('[role="status"]');

    this.#feed.addEventListener('keydown', (event) => {
      const current = event.target.closest('[role="article"]');
      if (!current) return;
      const items = [...this.#feed.querySelectorAll('[role="article"]')];
      const index = items.indexOf(current);

      if (event.key === 'PageDown') { event.preventDefault(); items[index + 1]?.focus(); }
      if (event.key === 'PageUp') { event.preventDefault(); items[index - 1]?.focus(); }
    });
  }

  async append(items) {
    this.#feed.setAttribute('aria-busy', 'true');
    try {
      const offset = this.#feed.querySelectorAll('[role="article"]').length;
      for (const [i, item] of items.entries()) {
        const article = item;
        article.setAttribute('aria-posinset', String(offset + i + 1));
        article.setAttribute('aria-setsize', '-1');
        this.#feed.append(article);
      }
      this.#status.textContent = `${items.length} new items.`;
    } finally {
      // Always reset, even on failure.
      this.#feed.setAttribute('aria-busy', 'false');
    }
  }
}

customElements.define('a11y-feed', A11yFeed);
```

### Don't

```js
// DON'T: articles and headings in a shadow root.
//     → Headings inside a shadow root do NOT appear in the document's heading
//       outline (see accordion.md), and heading navigation is the primary way
//       users move through a feed (RAWeb 9.1). The feed becomes unnavigable.
root.innerHTML = `<div role="feed"><slot></slot></div>`;
```

---

## Verify

- **The footer check — the one that matters.** Load the page, then Tab (or
  scroll) toward the footer. **Can you reach it?** If content keeps appearing
  between you and the privacy link, you have a keyboard trap (RAWeb 12.9). This
  is the check that fails on most real feeds.
- **The heading check:** navigate by heading (NVDA `H`, VoiceOver
  `Ctrl+Opt+Cmd+H`). You must land on each article. If nothing happens, your
  articles have no headings (RAWeb 9.1).
- **The loading check:** press "Load more". A screen reader must announce the
  result *without* focus moving. If it announces every article, `aria-live` is on
  the feed.
- **The busy check:** break the network (offline in devtools) and press "Load
  more". Is `aria-busy` still `"true"`? The feed is now announced as permanently
  loading.
- **The focus check:** load more while focused on item 3. Focus must **stay** on
  item 3.
- **Automated:** axe catches invalid `role="feed"` children (only `article` is
  allowed) and missing names. It catches **nothing** about the footer trap,
  stuck `aria-busy`, or focus theft.
