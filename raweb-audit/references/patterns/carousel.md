# Carousel — code examples

**Contract (ARIA, states, keyboard, RAWeb criteria):** run
`scripts/raweb-component-lookup.sh show carousel`

> **RAWeb 13.8 makes this pattern pass or fail on one thing:** moving content
> must be controllable. An auto-rotating carousel with no pause control is a
> straight failure, not a warning. Verify it:
> `scripts/raweb-lookup.sh criterion 13.8`.

---

## Universal rules

- **The easiest way to pass 13.8 is not to auto-rotate.** Genuinely. Auto-rotation
  buys almost nothing — carousel click-through rates are famously dismal — and it
  costs you a pause button, hover/focus pausing, live-region management, and a
  reduced-motion path. If the business case is "the homepage needs to fit five
  messages", the honest answer is that it doesn't.
- **If it auto-rotates, a visible pause control is mandatory.** Keyboard
  reachable, and first in the DOM so it's found before the moving content.
  (RAWeb 13.8)
- **Auto-rotation must pause on hover AND on focus.** Otherwise a keyboard user
  tabbing through slide 2's link has the content slide out from under them
  mid-Tab. (RAWeb 13.8, 7.3)
- **Off-screen slides must be `hidden` or `inert`.** Translating them off-screen
  leaves *every* slide's links in the tab order simultaneously — the user tabs
  into invisible content. (RAWeb 10.8)
- **`aria-live` only makes sense while paused.** During rotation it would
  announce endlessly. Set `aria-live="off"` while rotating, `"polite"` when
  paused. (RAWeb 7.5)
- **`prefers-reduced-motion: reduce` means do not auto-rotate at all.** Not
  "animate faster" — don't rotate.
- **`aria-roledescription="carousel"` renames the widget; it is not a name.** You
  still need `aria-label`.

---

## Vanilla

### Do — the version that passes by construction

```html
<!-- No auto-rotation: RAWeb 13.8 does not apply, and there is nothing to get
     wrong. This is the recommended default. -->
<section aria-roledescription="carousel" aria-label="Featured projects">
  <div class="carousel__viewport">
    <div class="carousel__slide" role="group" aria-roledescription="slide" aria-label="1 of 3">
      <img src="p1.jpg" alt="">
      <h3><a href="/projects/1">Riverside housing</a></h3>
    </div>
    <div class="carousel__slide" role="group" aria-roledescription="slide" aria-label="2 of 3" hidden>…</div>
    <div class="carousel__slide" role="group" aria-roledescription="slide" aria-label="3 of 3" hidden>…</div>
  </div>

  <button type="button" class="carousel__prev">
    <svg aria-hidden="true" focusable="false"><use href="#icon-left"/></svg>
    <span class="sr-only">Previous slide</span>
  </button>
  <button type="button" class="carousel__next">
    <svg aria-hidden="true" focusable="false"><use href="#icon-right"/></svg>
    <span class="sr-only">Next slide</span>
  </button>
</section>
```

### Do — auto-rotating, done properly

```html
<section id="carousel" aria-roledescription="carousel" aria-label="Featured projects">
  <!-- The pause button comes FIRST in the DOM: a keyboard user must be able to
       stop the motion before tabbing into content that is moving (RAWeb 13.8). -->
  <button type="button" id="carousel-toggle" class="carousel__toggle">
    <span class="sr-only">Pause automatic slide rotation</span>
    <svg aria-hidden="true" focusable="false"><use href="#icon-pause"/></svg>
  </button>

  <!-- aria-live is managed in JS: "off" while rotating, "polite" when paused. -->
  <div id="carousel-slides" class="carousel__viewport" aria-live="off">
    <div class="carousel__slide" role="group" aria-roledescription="slide" aria-label="1 of 3">
      <img src="p1.jpg" alt="">
      <h3><a href="/projects/1">Riverside housing</a></h3>
    </div>
    <div class="carousel__slide" role="group" aria-roledescription="slide" aria-label="2 of 3" hidden>…</div>
    <div class="carousel__slide" role="group" aria-roledescription="slide" aria-label="3 of 3" hidden>…</div>
  </div>

  <button type="button" id="carousel-prev"><span class="sr-only">Previous slide</span></button>
  <button type="button" id="carousel-next"><span class="sr-only">Next slide</span></button>
</section>
```

```css
.carousel__toggle:focus-visible,
.carousel__prev:focus-visible,
.carousel__next:focus-visible {
  outline: 3px solid #fff;
  outline-offset: 2px;
  /* Controls sit over photography: a single-colour ring can vanish against a
     light image. The shadow guarantees contrast on any background (RAWeb 10.7). */
  box-shadow: 0 0 0 5px #000;
}

.carousel__toggle,
.carousel__prev,
.carousel__next {
  min-inline-size: 44px;
  min-block-size: 44px;
}
```

```js
const carousel = document.getElementById('carousel');
const slidesContainer = document.getElementById('carousel-slides');
const slides = [...carousel.querySelectorAll('.carousel__slide')];
const toggle = document.getElementById('carousel-toggle');

const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)');
let index = 0;
let timer = null;

function show(newIndex) {
  index = (newIndex + slides.length) % slides.length;
  // `hidden`, not a transform: off-screen slides must leave the a11y tree AND
  // the tab order, or every slide's links are tabbable at once (RAWeb 10.8).
  slides.forEach((slide, i) => { slide.hidden = i !== index; });
}

function play() {
  if (prefersReducedMotion.matches) return; // never auto-rotate under reduce
  timer = setInterval(() => show(index + 1), 5000);
  toggle.querySelector('.sr-only').textContent = 'Pause automatic slide rotation';
  // Rotating: announcing every slide would be relentless.
  slidesContainer.setAttribute('aria-live', 'off');
}

function pause({ userInitiated = false } = {}) {
  clearInterval(timer);
  timer = null;
  if (userInitiated) {
    toggle.querySelector('.sr-only').textContent = 'Start automatic slide rotation';
  }
  // Paused: slide changes are now user-driven, so announcing them is useful.
  slidesContainer.setAttribute('aria-live', 'polite');
}

toggle.addEventListener('click', () => {
  timer ? pause({ userInitiated: true }) : play();
});

document.getElementById('carousel-next').addEventListener('click', () => {
  pause({ userInitiated: true }); // an explicit interaction ends auto-rotation
  show(index + 1);
});
document.getElementById('carousel-prev').addEventListener('click', () => {
  pause({ userInitiated: true });
  show(index - 1);
});

// Pause on hover AND on focus-within — otherwise content moves out from under
// a keyboard user mid-Tab (RAWeb 13.8).
carousel.addEventListener('mouseenter', () => timer && pause());
carousel.addEventListener('mouseleave', () => { if (!timer) play(); });
carousel.addEventListener('focusin', () => timer && pause());
carousel.addEventListener('focusout', (event) => {
  if (!carousel.contains(event.relatedTarget) && !timer) play();
});

show(0);
if (!prefersReducedMotion.matches) play();
prefersReducedMotion.addEventListener('change', (e) => {
  e.matches ? pause() : play();
});
```

### Don't

```html
<!-- DON'T: auto-rotation with no pause control.
     → Straight RAWeb 13.8 failure. Not a warning — a failure. Anyone who reads
       slowly, or is mid-sentence in a screen reader, loses the content. -->
<div class="carousel" data-autoplay="5000">
  <div class="slide">…</div>
</div>

<!-- DON'T: pause control last in the DOM.
     → The user must tab THROUGH the moving content to reach the thing that
       stops it. Put it first. -->
<div class="carousel__viewport">…</div>
<button type="button">Pause</button>

<!-- DON'T: aria-live="polite" on a rotating container.
     → Announces a new slide every 5 seconds, forever, interrupting whatever
       the user is reading elsewhere on the page. Only live while paused. -->
<div class="carousel__viewport" aria-live="polite">…</div>

<!-- DON'T: aria-roledescription with no accessible name.
     → Announced as "carousel" with no idea which one. roledescription RENAMES
       the role; it does not name the widget. -->
<section aria-roledescription="carousel">…</section>

<!-- DON'T: icon-only controls with no name.
     → "button, button, button". -->
<button type="button" class="carousel__next">
  <svg><use href="#icon-right"/></svg>
</button>

<!-- DON'T: dots as unlabelled buttons.
     → "button 1, button 2, button 3" tells the user nothing about where they
       are or what they would get. -->
<button type="button" class="dot"></button>
<button type="button" class="dot"></button>
```

```css
/* DON'T: hide slides by translating them.
   → All three slides stay in the accessibility tree and the tab order. The user
     tabs into links on slides they cannot see, and the screen reader reads the
     whole carousel as one wall of text (RAWeb 10.8). Use `hidden`. */
.carousel__viewport { overflow: hidden; }
.carousel__slide { transform: translateX(100%); }
.carousel__slide--active { transform: translateX(0); }
```

```js
// DON'T: rotate regardless of prefers-reduced-motion.
//     → For a vestibular-disorder user, an unrequested 5-second slide
//       transition can cause real nausea. Under `reduce`, do not rotate at all.
setInterval(() => show(index + 1), 5000);

// DON'T: pause on hover only.
//     → A keyboard user never hovers. They tab into slide 2's link, and the
//       carousel advances mid-Tab, moving the link away under them. Use
//       focusin/focusout too (RAWeb 13.8).
carousel.addEventListener('mouseenter', pause);
carousel.addEventListener('mouseleave', play);

// DON'T: resume rotation after an explicit user action.
//     → The user pressed "next" — they are reading. Restarting the timer fights
//       them. An explicit interaction should end auto-rotation for the session.
nextButton.addEventListener('click', () => { show(index + 1); play(); });
```

---

## React

### Do

```jsx
import { useCallback, useEffect, useId, useRef, useState } from 'react';

export function Carousel({ slides, label, autoRotate = false }) {
  const [index, setIndex] = useState(0);
  const [isPlaying, setIsPlaying] = useState(autoRotate);
  const [isPaused, setIsPaused] = useState(false); // hover/focus, not user intent
  const id = useId();
  const reduceMotion = useRef(false);

  useEffect(() => {
    const mq = window.matchMedia('(prefers-reduced-motion: reduce)');
    reduceMotion.current = mq.matches;
    if (mq.matches) setIsPlaying(false);
    const onChange = (e) => setIsPlaying(e.matches ? false : autoRotate);
    mq.addEventListener('change', onChange);
    return () => mq.removeEventListener('change', onChange);
  }, [autoRotate]);

  useEffect(() => {
    if (!isPlaying || isPaused || reduceMotion.current) return;
    const timer = setInterval(() => setIndex((i) => (i + 1) % slides.length), 5000);
    return () => clearInterval(timer);
  }, [isPlaying, isPaused, slides.length]);

  const goTo = useCallback((next) => {
    setIsPlaying(false); // explicit interaction ends auto-rotation
    setIndex((i) => (i + next + slides.length) % slides.length);
  }, [slides.length]);

  return (
    <section
      aria-roledescription="carousel"
      aria-label={label}
      onMouseEnter={() => setIsPaused(true)}
      onMouseLeave={() => setIsPaused(false)}
      onFocus={() => setIsPaused(true)}
      onBlur={(e) => {
        if (!e.currentTarget.contains(e.relatedTarget)) setIsPaused(false);
      }}
    >
      {/* First in the DOM, and only rendered when there is motion to control. */}
      {autoRotate && !reduceMotion.current && (
        <button type="button" onClick={() => setIsPlaying((p) => !p)}>
          <span className="sr-only">
            {isPlaying ? 'Pause automatic slide rotation' : 'Start automatic slide rotation'}
          </span>
        </button>
      )}

      {/* Live only when not auto-rotating (RAWeb 7.5). */}
      <div aria-live={isPlaying ? 'off' : 'polite'}>
        {slides.map((slide, i) => (
          <div
            key={slide.id}
            id={`${id}-slide-${i}`}
            role="group"
            aria-roledescription="slide"
            aria-label={`${i + 1} of ${slides.length}`}
            hidden={i !== index}   // hidden, not transform (RAWeb 10.8)
          >
            {slide.content}
          </div>
        ))}
      </div>

      <button type="button" onClick={() => goTo(-1)}>
        <span className="sr-only">Previous slide</span>
      </button>
      <button type="button" onClick={() => goTo(1)}>
        <span className="sr-only">Next slide</span>
      </button>
    </section>
  );
}
```

### Don't

```jsx
// DON'T: setInterval with no cleanup.
//     → The timer survives unmount and keeps calling setState on a dead
//       component. Return the clearInterval.
useEffect(() => {
  setInterval(() => setIndex((i) => i + 1), 5000);
}, []);

// DON'T: render only the active slide while animating a transform.
//     → Pick one: `hidden` on all inactive slides (accessible), or a CSS
//       transform (then they are all still tabbable — not accessible).
//       Transform + all slides mounted is the default of most carousel
//       libraries, and it is the RAWeb 10.8 failure.

// DON'T: a carousel library with no pause API.
//     → If you cannot stop it, you cannot pass 13.8. Check before adopting.
```

---

## Angular

### Do

```ts
import { Component, effect, input, signal, OnDestroy } from '@angular/core';

@Component({
  selector: 'app-carousel',
  host: {
    'aria-roledescription': 'carousel',
    '(mouseenter)': 'paused.set(true)',
    '(mouseleave)': 'paused.set(false)',
    '(focusin)': 'paused.set(true)',
    '(focusout)': 'onFocusOut($event)',
  },
  template: `
    @if (autoRotate() && !reduceMotion) {
      <button type="button" (click)="togglePlay()">
        <span class="sr-only">
          {{ playing() ? 'Pause automatic slide rotation' : 'Start automatic slide rotation' }}
        </span>
      </button>
    }

    <div [attr.aria-live]="playing() ? 'off' : 'polite'">
      @for (slide of slides(); track slide.id; let i = $index) {
        <div
          role="group"
          aria-roledescription="slide"
          [attr.aria-label]="(i + 1) + ' of ' + slides().length"
          [hidden]="i !== index()"
        >
          <ng-container [ngTemplateOutlet]="slide.template" />
        </div>
      }
    </div>

    <button type="button" (click)="goTo(-1)"><span class="sr-only">Previous slide</span></button>
    <button type="button" (click)="goTo(1)"><span class="sr-only">Next slide</span></button>
  `,
})
export class CarouselComponent implements OnDestroy {
  readonly slides = input.required<{ id: string; template: any }[]>();
  readonly autoRotate = input(false);

  protected readonly index = signal(0);
  protected readonly playing = signal(false);
  protected readonly paused = signal(false);
  protected readonly reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  private timer?: ReturnType<typeof setInterval>;

  constructor() {
    effect(() => {
      clearInterval(this.timer);
      if (!this.playing() || this.paused() || this.reduceMotion) return;
      this.timer = setInterval(() => {
        this.index.update((i) => (i + 1) % this.slides().length);
      }, 5000);
    });
  }

  ngOnDestroy(): void {
    clearInterval(this.timer);
  }

  protected togglePlay(): void { this.playing.update((p) => !p); }

  protected goTo(delta: number): void {
    this.playing.set(false); // explicit interaction ends rotation
    this.index.update((i) => (i + delta + this.slides().length) % this.slides().length);
  }

  protected onFocusOut(event: FocusEvent): void {
    const host = event.currentTarget as HTMLElement;
    if (!host.contains(event.relatedTarget as Node)) this.paused.set(false);
  }
}
```

### Don't

```html
<!-- DON'T: [attr.hidden] on slides — renders hidden="false" and hides
     everything. Use [hidden]. -->
<div role="group" [attr.hidden]="i !== index()">…</div>
```

```ts
// DON'T: no ngOnDestroy.
//     → The interval outlives the component and keeps mutating signals.
```

---

## Web Component

### Do

```js
// Light DOM: the author owns the slide markup, and hiding/showing real
// light-DOM slides keeps the tab order and the a11y tree honest.
class A11yCarousel extends HTMLElement {
  #slides = [];
  #index = 0;
  #timer = null;
  #mq = window.matchMedia('(prefers-reduced-motion: reduce)');

  connectedCallback() {
    this.#slides = [...this.querySelectorAll('[aria-roledescription="slide"]')];
    const toggle = this.querySelector('[data-carousel-toggle]');

    toggle?.addEventListener('click', () => (this.#timer ? this.pause(true) : this.play()));
    this.querySelector('[data-carousel-next]')?.addEventListener('click', () => {
      this.pause(true); this.#show(this.#index + 1);
    });
    this.querySelector('[data-carousel-prev]')?.addEventListener('click', () => {
      this.pause(true); this.#show(this.#index - 1);
    });

    this.addEventListener('mouseenter', () => this.#timer && this.pause());
    this.addEventListener('mouseleave', () => !this.#timer && this.play());
    this.addEventListener('focusin', () => this.#timer && this.pause());
    this.addEventListener('focusout', (e) => {
      if (!this.contains(e.relatedTarget) && !this.#timer) this.play();
    });

    this.#show(0);
    if (this.hasAttribute('auto-rotate')) this.play();
  }

  disconnectedCallback() { clearInterval(this.#timer); }

  #show(i) {
    this.#index = (i + this.#slides.length) % this.#slides.length;
    this.#slides.forEach((s, n) => { s.hidden = n !== this.#index; });
  }

  play() {
    if (this.#mq.matches) return; // reduced motion: never auto-rotate
    this.#timer = setInterval(() => this.#show(this.#index + 1), 5000);
    this.querySelector('[aria-live]')?.setAttribute('aria-live', 'off');
  }

  pause() {
    clearInterval(this.#timer);
    this.#timer = null;
    this.querySelector('[aria-live]')?.setAttribute('aria-live', 'polite');
  }
}

customElements.define('a11y-carousel', A11yCarousel);
```

### Don't

```js
// DON'T: slides in a shadow root behind a transform.
//     → Combines both failures: every slide stays tabbable (RAWeb 10.8) and the
//       shadow boundary makes it harder to notice in testing.

// DON'T: no disconnectedCallback.
//     → The interval keeps running after the element is removed.
```

---

## Verify

- **The RAWeb 13.8 check, first:** does it auto-rotate? If yes — is there a
  visible pause control, reachable by keyboard, that actually stops it? No is a
  **failure**, not a warning.
- **The Tab-out-from-under check:** start rotation, then Tab into a link on the
  current slide. The rotation must **stop**. If the slide changes while you're
  tabbing, the link moves away under you.
- **The tab-order check:** Tab through the whole carousel. You must reach the
  links on the **visible slide only**. If you hit links on slides you cannot see,
  they're hidden with a transform (RAWeb 10.8).
- **Reduced motion:** enable `prefers-reduced-motion: reduce`. It must not rotate
  at all.
- **Screen reader:** while rotating, it must stay quiet. When paused, moving
  between slides should announce. If it announces every 5 seconds unprompted,
  `aria-live` is on during rotation.
- **Automated:** axe catches unnamed icon buttons. It catches **nothing** about
  13.8 — auto-rotation, missing pause, hover-only pausing, and transform-hidden
  slides are all invisible to scanners. This pattern is almost entirely manual.
