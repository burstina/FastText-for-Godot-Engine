# FastText for Godot Engine ALPHA 1.0
Fast text class for Godot Engine. It is a workaround for FPS drop on **android devices** when using Label and LineEdit nodes.

## THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT."
## NO WARRANTY, USE AT YOUR OWN RISK! ##

Godot 3.1 text rendering is not performing well on android devices: https://github.com/godotengine/godot/issues/19917
FPS rapidly decrease from 60 to 45 just using 3 standard *labels*, that's no good.
I made this custom class to keep performances in line.

You can use it as *Label*  setting **Allow Input** to *false*
You can use it as *LineEdit (kind of)*  setting **Allow Input** to *true*

Allowing input means that an *Input Box* will appear runtime to allow text to be entered and saved in FastText node.
Since it was developed with mobile devices in mind, standard Input Box will appear at the top of the screen (coord: 0,0) with full screen length. If you don't want this to happen, you can set custom position and size.
As default, newly runtime-created Input Box will be put in Scene Tree as sibiling, but sometimes it is just not good: you can set a different location by using  **Input Box Parent**
If you don't like standard input box, you can have one of your own nodes by using **Input Node**


## Class custom properties

|  Property  |domain|mandatory|desc|
|--|--|--|--|
| **Fast Text**  | bool | no| activate Fast Text capabilities. Set to *false* to use as basic *label* node |
| **Allow Input** | bool | no | activate to use this node in a *LineEdit* kind of way |
| **Target Type** | control/sprite| yes | target rendered object. Default is *control*, but you can change as you please, if needed. Not considered when **Allow Input** is true |


When **Allow Input is true**, following properties are considered:


|  Property  |domain|mandatory|desc|
|--|--|--|--|
| **Input Node**  | NodePath | no |  you can specify a *TextEdit* node you already put in Scene Tree you want to use instead of default input box. |
| **Input Box Parent** | NodePath | no | you can specify a node in Scene Tree where you want put the default input box as a child. **  |
|  | | |`NOTE` : </font> **Input Node** and **Input Box Parent** are mutually exclusive. If you leave them empty, Input Box will be created as a sibiling |
| **Input Box Script** | File Path | yes | mandatory when **Allow Input** is true |


When **Input Node is blank**, custom Input Box will be created using following properties:


|  Property  |domain|mandatory|desc|
|--|--|--|--|
| **Input Box Style Inherited** | bool | no | Input Box Style will be the same of TextEdit node |
| **Input Box Style**  | StyleBox| no | Custom Style for Input Box|
| **Input Box Font Inherited** | bool | no | Input Box Font will be the same of TextEdit node |
| **Input Box Font**  | Font | no | Custom Font for Input Box|
| **Input Box Full Width**  | bool| no | when set to *true*, override width for Input Box will to screen full width |
| **Input Box Custom Rect** | Rect2 | no | position and size for default Input Box |





