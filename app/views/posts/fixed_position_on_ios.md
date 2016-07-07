# Fixed Position Bug on iOS

The `fixed` value for the `position` property has a very noticeable glitch in
iOS9 (and parhaps many other versions). ==When you scroll vertically, the
`fixed` elements can take a slightly different position than intended.==

We can somewhat fix it by establishing the height and width of the body and
html, while simultaneously setting the overflow to auto and
webkit-overflow-scrolling to touch.

==Fix:==

```scss
body,
html {
  height: 100vh;
  overflow: auto;
  -webkit-overflow-scrolling: touch;
  width: 100vw;
}
```

==This will prevent the menubar from retracting (which might be very
undesirable)== but it does improve the scrolling experience. It is a trade that
I am willing to make for the time being.
