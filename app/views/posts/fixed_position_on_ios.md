# Fixed Position Bug on iOS

The `fixed` value for the `position` property has a very noticeable glitch in
iOS9 and parhaps many other versions. ==When scrolling vertically the
`fixed` elements can take a different position than intended.== A fixed header
could settle 5 to 10 pixels from the top, or a footer might get cut off.

We can fix it by establishing the height and width of the `body` and
`html` and setting the `overflow` to auto and
`webkit-overflow-scrolling` to touch.

==Fixed Position Scrolling Solution:==

```scss
body,
html {
  height: 100vh;
  overflow: auto;
  -webkit-overflow-scrolling: touch;
  width: 100vw;
}
```

==This prevents the browser's menubar from retracting which allows for the fixed
elements to take their intended position.== It does improve the
scrolling experience, but it also leaves us with an omnipresent menubar.
