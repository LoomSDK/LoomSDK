
Quick start:

1. Launch tools/lmldesigner/index.html in Chrome.
2. In the prompt dialog, enter the path to the directory that contains your project's image files
3. Drag and drop images from this image directory only.
4. Click an image that appears in the image pool to add it to the scene as an object.

Tips:

* The tweening you set up for a specific view happens when that view is made the current view (on enter).
* The enter event is a transition from __root to the current view, an exit event is one from the current view back to __root. This is how code is generated.
* The __root view describes the exit state of all other views. It can not be deleted.
* Use images for every object. The exporter will add class specific fields for you to change.
* If you don't know what's happening, look in the log. Things of interest will blink to get your attention.
* All new views are created by copying the __root view.
* There is currently no way to set z-index for objects. Plan ahead if objects must overlap. Subsequent objects are spawned on top of older ones.
* Select an object by hovering the mouse over it until you see the red dashed border.
* Directly edit object properties (such as variable name) by double-clicking an object.

Shortcuts:

Hover mouse over an object to select it. When selected, use these keys to edit your views faster:

* Keys 0-9 will modify the delay of the current view's (enter) tween
* SHIFT + Keys 0-9 will modify the duration of the tweening of position, scale and opacity properties on the selected object for the currently selected view
* Cursor keys will nudge the position by one pixel. Press SHIFT to make that 16 pixels per nudge.
* SHIFT + drag the object to make it snap to either axis.
* Select the object by hovering over it and hit the DEL key to remove the object from the scene.