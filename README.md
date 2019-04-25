# FastText-for-Godot-Engine
Fast text class for Godot Engine. It is a workaround for FPS drop on android devices when using Label and LineEdit nodes.

## Class custom properties

|  Property  |domain|mandatory|desc|
|--|--|--|--|
| **Fast Text**  | bool | no| activate Fast Text capabilities. Set to *false* to use as standard *label* node |
| **Allow Input** | bool | no | activate to use it as a *LineEdit* kind of way |
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
| **Input Box Full Width**  | bool| no | when set to *true*, width for Input Box will overriden to screen full width |
| **Input Box Custom Rect** | Rect2 | no | position and size for default Input Box |





