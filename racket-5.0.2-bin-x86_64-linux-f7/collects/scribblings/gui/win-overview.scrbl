#lang scribble/doc
@(require scribble/eval
          "common.ss"
          "diagrams.ss")

@title[#:tag "windowing-overview"]{Windowing}

The Racket windowing toolbox provides the basic building blocks of GUI
 programs, including frames (top-level windows), modal dialogs, menus,
 buttons, check boxes, text fields, and radio buttons.  The toolbox
 provides these building blocks via built-in classes, such as the
 @scheme[frame%] class:

@schemeblock[
(code:comment @#,t{Make a frame by instantiating the @scheme[frame%] class})
(define frame (new frame% [label "Example"]))
 
(code:comment @#,t{Show the frame by calling its @method[top-level-window<%> show] method})
(send frame #,(:: top-level-window<%> show) #t)
]

The built-in classes provide various mechanisms for handling GUI
 events. For example, when instantiating the @scheme[button%] class,
 the programmer supplies an event callback procedure to be invoked
 when the user clicks the button. The following example program
 creates a frame with a text message and a button; when the user
 clicks the button, the message changes:

@schemeblock[
(code:comment @#,t{Make a frame by instantiating the @scheme[frame%] class})
(define frame (new frame% [label "Example"]))

(code:comment @#,t{Make a static text message in the frame})
(define msg (new message% [parent frame]
                          [label "No events so far..."]))

(code:comment @#,t{Make a button in the frame})
(new button% [parent frame] 
             [label "Click Me"]
             (code:comment @#,t{Callback procedure for a button click:})
             (callback (lambda (button event) 
                         (send msg #,(method message% set-label) "Button click"))))

(code:comment @#,t{Show the frame by calling its @scheme[show] method})
(send frame #,(:: top-level-window<%> show) #t)
]

Programmers never implement the GUI event loop directly. Instead, the
 system automatically pulls each event from an internal queue and
 dispatches the event to an appropriate window. The dispatch invokes
 the window's callback procedure or calls one of the window's
 methods. In the above program, the system automatically invokes the
 button's callback procedure whenever the user clicks @onscreen{Click
 Me}.

If a window receives multiple kinds of events, the events are
 dispatched to methods of the window's class instead of to a callback
 procedure. For example, a drawing canvas receives update events,
 mouse events, keyboard events, and sizing events; to handle them, a
 programmer must derive a new class from the built-in
 @scheme[canvas%] class and override the event-handling methods. The
 following expression extends the frame created above with a canvas
 that handles mouse and keyboard events:

@schemeblock[
(code:comment @#,t{Derive a new canvas (a drawing window) class to handle events})
(define my-canvas%
  (class canvas% (code:comment @#,t{The base class is @scheme[canvas%]})
    (code:comment @#,t{Define overriding method to handle mouse events})
    (define/override (#,(:: canvas<%> on-event) event)
      (send msg #,(:: message% set-label) "Canvas mouse"))
    (code:comment @#,t{Define overriding method to handle keyboard events})
    (define/override (#,(:: canvas<%> on-char) event)
      (send msg #,(:: message% set-label) "Canvas keyboard"))
    (code:comment @#,t{Call the superclass init, passing on all init args})
    (super-new)))

(code:comment @#,t{Make a canvas that handles events in the frame})
(new my-canvas% [parent frame])
]

After running the above code, manually resize the frame to see the
 new canvas.  Moving the cursor over the canvas calls the canvas's
 @method[canvas<%> on-event] method with an object representing a
 motion event. Clicking on the canvas calls @method[canvas<%>
 on-event]. While the canvas has the keyboard focus, typing on the
 keyboard invokes the canvas's @method[canvas<%> on-char] method.

The system dispatches GUI events sequentially; that is, after invoking
 an event-handling callback or method, the system waits until the
 handler returns before dispatching the next event. To illustrate the
 sequential nature of events, we extend the frame again, adding a
 @onscreen{Pause} button:

@schemeblock[
(new button% [parent frame] 
             [label "Pause"]
             [callback (lambda (button event) (sleep 5))])
]

After the user clicks @onscreen{Pause}, the entire frame becomes
 unresponsive for five seconds; the system cannot dispatch more events
 until the call to @scheme[sleep] returns. For more information about
 event dispatching, see @secref["eventspaceinfo"].

In addition to dispatching events, the GUI classes also handle the
 graphical layout of windows. Our example frame demonstrates a simple
 layout; the frame's elements are lined up top-to-bottom. In general,
 a programmer specifies the layout of a window by assigning each GUI
 element to a parent @tech{container}. A vertical container, such
 as a frame, arranges its children in a column, and a horizontal
 container arranges its children in a row. A container can be a child
 of another container; for example, to place two buttons side-by-side
 in our frame, we create a horizontal panel for the new buttons:

@schemeblock[
(define panel (new horizontal-panel% [parent frame]))
(new button% [parent panel]
             [label "Left"]
             [callback (lambda (button event) 
                         (send msg #,(:: message% set-label) "Left click"))])
(new button% [parent panel]
             [label "Right"]
             [callback (lambda (button event) 
                         (send msg #,(:: message% set-label) "Right click"))])
]

For more information about window layout and containers, see
 @secref["containeroverview"].

@section{Core Windowing Classes}

The fundamental graphical element in the windowing toolbox is an
 @deftech{area}. The following classes implement the different types
 of areas in the windowing toolbox:

@itemize[

 @item{@deftech{Containers} --- areas that can
 contain other areas:

 @itemize[

 @item{@scheme[frame%] --- a @deftech{frame} is a top-level window
 that the user can move and resize.}

 @item{@scheme[dialog%] --- a @deftech{dialog} is a modal top-level
 window; when a dialog is shown, other top-level windows are disabled
 until the dialog is dismissed.}

 @item{@scheme[panel%] --- a @deftech{panel} is a subcontainer
 within a container. The toolbox provides three subclasses of
 @scheme[panel%]: @scheme[vertical-panel%],
 @scheme[horizontal-panel%], and @scheme[tab-panel%].}

 @item{@scheme[pane%] --- a @deftech{pane} is a lightweight panel.
 It has no graphical representation or event-handling capabilities.
 The @scheme[pane%] class has three subclasses:
 @scheme[vertical-pane%], @scheme[horizontal-pane%], and
 @scheme[grow-box-spacer-pane%].}

 ]}

 @item{@deftech{Containees} --- areas that must be
 contained within other areas:

 @itemize[

 @item{@scheme[panel%] --- a panel is a containee as well as
 a container.}

 @item{@scheme[pane%] --- a pane is a containee as well as a
 container.}

 @item{@scheme[canvas%] --- a @deftech{canvas} is a subwindow for
 drawing on the screen.}

 @item{@scheme[editor-canvas%] --- an @deftech{editor canvas} is a
 subwindow for displaying a text editor or pasteboard editor. The
 @scheme[editor-canvas%] class is documented with the editor classes
 in @secref["editor-overview"].}

 @item{@deftech{Controls} --- containees that the user can manipulate:

 @itemize[

   @item{@scheme[message%] --- a @deftech{message} is a static
   text field or bitmap with no user interaction.}

   @item{@scheme[button%] --- a @deftech{button} is a clickable
   control.}

   @item{@scheme[check-box%] --- a @deftech{check box} is a
   clickable control; the user clicks the control to set or remove
   its check mark.}

   @item{@scheme[radio-box%] --- a @deftech{radio box} is a
   collection of mutually exclusive @deftech{radio buttons}; when the
   user clicks a radio button, it is selected and the radio box's
   previously selected radio button is deselected.}

   @item{@scheme[choice%] --- a @deftech{choice item} is a pop-up
   menu of text choices; the user selects one item in the control.}

   @item{@scheme[list-box%] --- a @deftech{list box} is a
   scrollable lists of text choices; the user selects one or more
   items in the list (depending on the style of the list box).}

   @item{@scheme[text-field%] --- a @deftech{text field} is a box
   for simple text entry.}

   @item{@scheme[combo-field%] --- a @deftech{combo field} combines
   a text field with a pop-up menu of choices.}

   @item{@scheme[slider%] --- a @deftech{slider} is a dragable
   control that selects an integer value within a fixed range.}

   @item{@scheme[gauge%] --- a @deftech{gauge} is an output-only
   control (the user cannot change the value) for reporting an integer
   value within a fixed range.}

  ]}

 ]}

]

As suggested by the above listing, certain @tech{areas}, called
 @tech{containers}, manage certain other areas, called
 @tech{containees}. Some areas, such as panels, are both
 @tech{containers} and @tech{containees}.

Most areas are @deftech{windows}, but some are
 @deftech{non-windows}. A @tech{window}, such as a @tech{panel}, has a
 graphical representation, receives keyboard and mouse events, and can
 be disabled or hidden.  In contrast, a @tech{non-window}, such as a
 @tech{pane}, is useful only for geometry management; a
 @tech{non-window} does not receive mouse events, and it cannot be
 disabled or hidden.

Every @tech{area} is an instance of the @scheme[area<%>]
 interface. Each @tech{container} is also an instance of the
 @scheme[area-container<%>] interface, whereas each @tech{containee}
 is an instance of @scheme[subarea<%>]. @tech{Windows} are instances
 of @scheme[window<%>]. The @scheme[area-container<%>],
 @scheme[subarea<%>], and @scheme[window<%>] interfaces are
 subinterfaces of @scheme[area<%>].

The following diagram shows more of the type hierarchy under
 @scheme[area<%>]:

@diagram->table[short-windowing-diagram]

The diagram below extends the one above to show the complete type
 hierarchy under @scheme[area<%>]. (Some of the types are represented
 by interfaces, and some types are represented by classes. In
 principle, every area type should be represented by an interface, but
 whenever the windowing toolbox provides a concrete implementation,
 the corresponding interface is omitted from the toolbox.)  To avoid
 intersecting lines, the hierarchy is drawn for a cylindrical surface;
 lines from @scheme[subarea<%>] and @scheme[subwindow<%>] wrap from
 the left edge of the diagram to the right edge.

@diagram->table[windowing-diagram]

Menu bars, menus, and menu items are graphical elements, but not areas
 (i.e., they do not have all of the properties that are common to
 areas, such as an adjustable graphical size).  Instead, the menu
 classes form a separate container--containee hierarchy:

@itemize[

 @item{@deftech{Menu Item Containers}

  @itemize[

  @item{@scheme[menu-bar%] --- a @deftech{menu bar} is a top-level
  collection of menus that are associated with a frame.}

  @item{@scheme[menu%] --- a @deftech{menu} contains a set of menu
  items. The menu can appear in a menu bar, in a popup menu, or as a
  submenu in another menu.}

  @item{@scheme[popup-menu%] --- a @deftech{popup menu} is a
  top-level menu that is dynamically displayed in a canvas or
  editor canvas.}

  ]}
  
 @item{@deftech{Menu Items}

  @itemize[
  
  @item{@scheme[separator-menu-item%] --- a @deftech{separator} is
  an unselectable line in a menu or popup menu.}

  @item{@scheme[menu-item%] --- a @deftech{plain menu item} is a
  selectable text item in a menu. When the item is selected, its
  callback procedure is invoked.}

  @item{@scheme[checkable-menu-item%] --- a @deftech{checkable menu
  item} is a text item in a menu; the user selects a checkable menu
  item to toggle a check mark next to the item.}

  @item{@scheme[menu%] --- a menu is a menu item as well as a menu
  item container.}

  ]}

]

The following diagram shows the complete type hierarchy for the menu
system:

@diagram->table[menu-diagram]

@; ------------------------------------------------------------------------

@section[#:tag "containeroverview"]{Geometry Management}

The windowing toolbox's geometry management makes it easy to design windows that look
 right on all platforms, despite different graphical representations
 of GUI elements. Geometry management is based on containers; each
 container arranges its children based on simple constraints, such as
 the current size of a frame and the natural size of a button.

The built-in container classes include horizontal panels (and panes),
 which align their children in a row, and vertical panels (and panes),
 which align their children in a column. By nesting horizontal and
 vertical containers, a programmer can achieve most any layout.  For
 example, we can construct a dialog with the following shape:

@verbatim[#:indent 2]{
  ------------------------------------------------------
 |              -------------------------------------   |
 |  Your name: |                                     |  |
 |              -------------------------------------   |
 |                    --------     ----                 |
 |                   ( Cancel )   ( OK )                |
 |                    --------     ----                 |
  ------------------------------------------------------
}

with the following program:

@schemeblock[
(code:comment @#,t{Create a dialog})
(define dialog (instantiate dialog% ("Example")))

(code:comment @#,t{Add a text field to the dialog})
(new text-field% [parent dialog] [label "Your name"])

(code:comment @#,t{Add a horizontal panel to the dialog, with centering for buttons})
(define panel (new horizontal-panel% [parent dialog]
                                     [alignment '(center center)]))

(code:comment @#,t{Add @onscreen{Cancel} and @onscreen{Ok} buttons to the horizontal panel})
(new button% [parent panel] [label "Cancel"])
(new button% [parent panel] [label "Ok"])
(when (system-position-ok-before-cancel?)
  (send panel #,(:: area-container<%> change-children) reverse))

(code:comment @#,t{Show the dialog})
(send dialog #,(:: dialog% show) #t)
]

Each container arranges its children using the natural size of each
 child, which usually depends on instantiation parameters of the
 child, such as the label on a button or the number of choices in a
 radio box. In the above example, the dialog stretches horizontally to
 match the minimum width of the text field, and it stretches
 vertically to match the total height of the field and the
 buttons. The dialog then stretches the horizontal panel to fill the
 bottom half of the dialog. Finally, the horizontal panel uses the sum
 of the buttons' minimum widths to center them horizontally.

As the example demonstrates, a stretchable container grows to fill its
 environment, and it distributes extra space among its stretchable
 children. By default, panels are stretchable in both directions,
 whereas buttons are not stretchable in either direction. The
 programmer can change whether an individual GUI element is
 stretchable.

The following subsections describe the container system in detail,
 first discussing the attributes of a containee in
 @secref["containees"], and then describing
 the attributes of a container in
 @secref["containers"]. In addition to the
 built-in vertical and horizontal containers, programmers can define
 new types of containers as discussed in the final subsection,
 @secref["new-containers"].


@subsection[#:tag "containees"]{Containees}

Each @tech{containee}, or child, has the following properties:

@itemize[
 
 @item{a @deftech{graphical minimum width} and a @deftech{graphical minimum height};}

 @item{a @deftech{requested minimum width} and a @deftech{requested minimum height};}

 @item{horizontal and vertical @deftech{stretchability} (on or off); and}

 @item{horizontal and vertical @tech{margins}.}

]

A @tech{container} arranges its children based on these four
 properties of each @tech{containee}. A @tech{containee}'s parent
 container is specified when the @tech{containee} is created, and the
 parent cannot be changed. However, a @tech{containee} can be
 @tech{hidden} or @tech{deleted} within its parent, as described in
 @secref["containers"].

The @deftech{graphical minimum size} of a particular containee, as
 reported by @method[area<%> get-graphical-min-size], depends on the
 platform, the label of the containee (for a control), and style
 attributes specified when creating the containee. For example, a
 button's minimum graphical size ensures that the entire text of the
 label is visible. The graphical minimum size of a control (such as a
 button) cannot be changed; it is fixed at creation time. (A control's
 minimum size is @italic{not} recalculated when its label is changed.)
 The graphical minimum size of a panel or pane depends on the total
 minimum size of its children and the way that they are arranged.

To select a size for a containee, its parent container considers the
 containee's @deftech{requested minimum size} rather than its
 graphical minimum size (assuming the requested minimum is larger than
 the graphical minimum). Unlike the graphical minimum, the requested
 minimum size of a containee can be changed by a programmer at any
 time using the @method[area<%> min-width] and
 @method[area<%> min-height] methods.

Unless a containee is stretchable (in a particular direction), it
 always shrinks to its minimum size (in the corresponding
 direction). Otherwise, containees are stretched to fill all available
 space in a container. Each containee begins with a default
 stretchability. For example, buttons are not initially stretchable,
 whereas a one-line text field is initially stretchable in the
 horizontal direction. A programmer can change the stretchability of a
 containee at any time using the @method[area<%> stretchable-width]
 and @method[area<%> stretchable-height] methods.

A @deftech{margin} is space surrounding a containee. Each containee's
 margin is independent of its minimum size, but from the container's
 point of view, a margin effectively increases the minimum size of the
 containee. For example, if a button has a vertical margin of
 @scheme[2], then the container must allocate enough room to leave two
 pixels of space above and below the button, in addition to the space
 that is allocated for the button's minimum height. A programmer can
 adjust a containee's margin with @method[subarea<%> horiz-margin] and
 @method[subarea<%> vert-margin]. The default margin is @scheme[2] for
 a control, and @scheme[0] for any other type of containee.

In practice, the @tech{requested minimum size} and @tech{margin} of a
 control are rarely changed, although they are often changed for a
 canvas. @tech{Stretchability} is commonly adjusted for any type of
 containee, depending on the visual effect desired by the programmer.


@subsection[#:tag "containers"]{Containers}

A container has the following properties:

@itemize[
 
 @item{a list of (non-deleted) children containees;}

 @item{a requested minimum width and a requested minimum height;}

 @item{a spacing used between the children;}

 @item{a border margin used around the total set of children;}

 @item{horizontal and vertical stretchability (on or off); and}

 @item{an alignment setting for positioning leftover space.}

]

These properties are factored into the container's calculation of its
 own size and the arrangement of its children. For a container that is
 also a containee (e.g., a panel), the container's requested minimum
 size and stretchability are the same as for its containee aspect.

A containee's parent container is specified when the containee is
 created, and the parent cannot be changed. However, a containee
 window can be @tech{hidden} or @tech{deleted} within its parent
 container (but a non-window containee cannot be @tech{hidden} or
 @tech{deleted}):

@itemize[

 @item{A @deftech{hidden} child is invisible to the user, but space is
 still allocated for each hidden child within a container. To hide or
 show a child, call the child's @method[window<%> show] method.}

 @item{A @deftech{deleted} child is hidden @italic{and} ignored by
 container as it arranges its other children, so no space is reserved
 in the container for a deleted child.  To make a child deleted or
 non-deleted, call the container's @method[area-container<%>
 delete-child] or @method[area-container<%> add-child] method (which
 calls the child's @method[window<%> show] method).}

]

When a child is created, it is initially shown and non-deleted. A
 deleted child is subject to garbage collection when no external
 reference to the child exists. A list of non-deleted children (hidden
 or not) is available from a container through its
 @method[area-container<%> get-children] method.

The order of the children in a container's non-deleted list is
 significant. For example, a vertical panel puts the first child in
 its list at the top of the panel, and so on. When a new child is
 created, it is put at the end of its container's list of
 children. The order of a container's list can be changed dynamically
 via the @method[area-container<%> change-children] method. (The
 @method[area-container<%> change-children] method can also be used to
 activate or deactivate children.)

The @tech{graphical minimum size} of a container, as reported by
 @method[area<%> get-graphical-min-size], is calculated by combining
 the minimum sizes of its children (summing them or taking the
 maximum, as appropriate to the layout strategy of the container)
 along with the spacing and border margins of the container. A larger
 minimum may be specified by the programmer using @method[area<%>
 min-width] and @method[area<%> min-height] methods; when the computed
 minimum for a container is larger than the programmer-specified
 minimum, then the programmer-specified minimum is ignored.

A container's spacing determines the amount of space left between
 adjacent children in the container, in addition to any space required
 by the children's margins. A container's border margin determines the
 amount of space to add around the collection of children; it
 effectively decreases the area within the container where children
 can be placed.  A programmer can adjust a container's border and
 spacing dynamically via the @method[area-container<%> border] and
 @method[area-container<%> spacing] methods. The default border and
 spacing are @scheme[0] for all container types.

Because a panel or pane is a containee as well as a container, it has
 a containee margin in addition to its border margin. For a panel,
 these margins are not redundant because the panel can have a
 graphical border; the border is drawn inside the panel's containee
 margin, but outside the panel's border margin.

For a top-level-window container, such as a frame or dialog, the
 container's stretchability determines whether the user can resize the
 window to something larger than its minimum size. Thus, the user
 cannot resize a frame that is not stretchable. For other types of
 containers (i.e., panels and panes), the container's stretchability
 is its stretchability as a containee in some other container.  All
 types of containers are initially stretchable in both
 directions---except instances of @scheme[grow-box-spacer-pane%],
 which is intended as a lightweight spacer class rather than a useful
 container class---but a programmer can change the stretchability of
 an area at any time via the @method[area<%> stretchable-width] and
 @method[area<%> stretchable-height] methods.

The alignment specification for a container determines how it
 positions its children when the container has leftover space. (A
 container can only have leftover space in a particular direction when
 none of its children are stretchable in that direction.) For example,
 when the container's horizontal alignment is @indexed-scheme['left],
 the children are left-aligned in the container and leftover space is
 accumulated to the right.  When the container's horizontal alignment
 is @indexed-scheme['center], each child is horizontally centered in
 the container. A container's alignment is changed with the
 @method[area-container<%> set-alignment] method.

@subsection[#:tag "new-containers"]{Defining New Types of Containers}

Although nested horizontal and vertical containers can express most
 layout patterns, a programmer can define a new type of container with
 an explicit layout procedure. A programmer defines a new type of
 container by deriving a class from @scheme[panel%] or @scheme[pane%]
 and overriding the @method[area-container<%> container-size] and
 @method[area-container<%> place-children] methods. The
 @method[area-container<%> container-size] method takes a list of size
 specifications for each child and returns two values: the minimum
 width and height of the container. The @method[area-container<%>
 place-children] method takes the container's size and a list of size
 specifications for each child, and returns a list of sizes and
 placements (in parallel to the original list).

An input size specification is a list of four values:

@itemize[
 @item{the child's minimum width;}
 @item{the child's minimum height;}
 @item{the child's horizontal stretchability (@scheme[#t] means stretchable, @scheme[#f] means not stretchable); and}
 @item{the child's vertical stretchability.}
]

For @method[area-container<%> place-children], an output
 position and size specification is a list of four values:

@itemize[
 @item{the child's new horizontal position (relative to the parent);}
 @item{the child's new vertical position;}
 @item{the child's new actual width;}
 @item{the child's new actual height.}
]

The widths and heights for both the input and output include the
 children's margins. The returned position for each child is
 automatically incremented to account for the child's margin in
 placing the control.


@section[#:tag "mouseandkey"]{Mouse and Keyboard Events}

Whenever the user moves the mouse, clicks or releases a mouse button,
 or presses a key on the keyboard, an event is generated for some
 window. The window that receives the event depends on the current
 state of the graphic display:

@itemize[

 @item{@index['("mouse events" "overview")]{The} receiving window of a
 mouse event is usually the window under the cursor when the mouse is
 moved or clicked. If the mouse is over a child window, the child
 window receives the event rather than its parent.

 When the user clicks in a window, the window ``grabs'' the mouse, so
 that @italic{all} mouse events go to that window until the mouse
 button is released (regardless of the location of the cursor). As a
 result, a user can click on a scrollbar thumb and drag it without
 keeping the cursor strictly inside the scrollbar control.

 A mouse button-release event is normally generated for each mouse
 button-down event, but a button-release event might get dropped. For
 example, a modal dialog might appear and take over the mouse. More
 generally, any kind of mouse event can get dropped in principle, so
 avoid algorithms that depend on precise mouse-event sequences. For
 example, a mouse tracking handler should reset the tracking state
 when it receives an event other than a dragging event.}

 @item{@index['("keyboard focus" "overview")]{@index['("keyboard
 events" "overview")]{The}} receiving window of a keyboard event is
 the window that owns the @deftech{keyboard focus} at the time of the
 event. Only one window owns the focus at any time, and focus
 ownership is typically displayed by a window in some manner. For
 example, a text field control shows focus ownership by displaying a
 blinking caret.

 Within a top-level window, only certain kinds of subwindows can have
 the focus, depending on the conventions of the platform. Furthermore,
 the subwindow that initially owns the focus is platform-specific. A
 user can moves the focus in various ways, usually by clicking the
 target window. A program can use the @method[window<%> focus] method
 to move the focus to a subwindow or to set the initial focus.

 Under X, a @indexed-scheme['wheel-up] or @indexed-scheme['wheel-down]
 event may be sent to a window other than the one with the keyboard
 focus, because X generates wheel events based on the location of the
 mouse pointer.

 A key-press event may correspond to either an actual key press or an
 auto-key repeat. Multiple key-press events without intervening
 key-release events normally indicate an auto-key. Like any input
 event, however, key-release events sometimes get dropped (e.g., due
 to the appearance of a modal dialog).}

]

Controls, such as buttons and list boxes, handle keyboard and mouse
 events automatically, eventually invoking the callback procedure that
 was provided when the control was created. A canvas propagates mouse
 and keyboard events to its @method[canvas<%> on-event] and
 @method[canvas<%> on-char] methods, respectively.

@index['("events" "delivery")]{A} mouse and keyboard event is
 delivered in a special way to its window. Each ancestor of the
 receiving window gets a chance to intercept the event through the
 @method[window<%> on-subwindow-event] and @method[window<%>
 on-subwindow-char] methods. See the method descriptions for more
 information.

@index['("keyboard focus" "navigation")]{The} default
 @method[window<%> on-subwindow-char] method for a top-level window
 intercepts keyboard events to detect menu-shortcut events and
 focus-navigation events. See @xmethod[frame% on-subwindow-char] and
 @xmethod[dialog% on-subwindow-char] for details.  Certain OS-specific
 key combinations are captured at a low level, and cannot be
 overridden. For example, under Windows and X, pressing and releasing
 Alt always moves the keyboard focus to the menu bar. Similarly,
 Alt-Tab switches to a different application under Windows. (Alt-Space
 invokes the system menu under Windows, but this shortcut is
 implemented by @method[top-level-window<%> on-system-menu-char],
 which is called by @xmethod[frame% on-subwindow-char] and
 @xmethod[dialog% on-subwindow-char].)

@; ------------------------------------------------------------------------

@section[#:tag "eventspaceinfo"]{Event Dispatching and Eventspaces}

@section-index["events" "dispatching"]

A graphical user interface is an inherently multi-threaded system: one
 thread is the program managing windows on the screen, and the other
 thread is the user moving the mouse and typing at the keyboard. GUI
 programs typically use an @deftech{event queue} to translate this
 multi-threaded system into a sequential one, at least from the
 programmer's point of view. Each user action is handled one at a
 time, ignoring further user actions until the previous one is
 completely handled. The conversion from a multi-threaded process to a
 single-threaded one greatly simplifies the implementation of GUI
 programs.

Despite the programming convenience provided by a purely sequential
 event queue, certain situations require a less rigid dialog with
 the user:

@itemize[

 @item{@italic{Nested event handling:} In the process of handling an
 event, it may be necessary to obtain further information from the
 user. Usually, such information is obtained via a modal dialog; in
 whatever fashion the input is obtained, more user events must be
 received and handled before the original event is completely
 handled. To allow the further processing of events, the handler for
 the original event must explicitly @deftech{yield} to the
 system. Yielding causes events to be handled in a nested manner,
 rather than in a purely sequential manner.}

 @item{@italic{Asynchronous event handling:} An application may
 consist of windows that represent independent dialogs with the
 user. For example, a drawing program might support multiple drawing
 windows, and a particularly time-consuming task in one window (e.g.,
 a special filter effect on an image) should not prevent the user from
 working in a different window. Such an application needs sequential
 event handling for each individual window, but asynchronous
 (potentially parallel) event handling across windows. In other words,
 the application needs a separate event queue for each window, and a
 separate event-handling thread for each event queue.}

]

An @deftech{eventspace} is a context for processing GUI
 events. Each eventspace maintains its own queue of events, and events
 in a single eventspace are dispatched sequentially by a designated
 @deftech{handler thread}. An event-handling procedure running in this
 handler thread can yield to the system by calling @scheme[yield], in
 which case other event-handling procedures may be called in a nested
 (but single-threaded) manner within the same handler thread. Events
 from different eventspaces are dispatched asynchronously by separate
 handler threads.

@index['("dialogs" "modal")]{When} a frame or dialog is created
 without a parent, it is associated with the @tech{current eventspace}
 as described in @secref["currenteventspace"].  Events for a
 top-level window and its descendants are always dispatched in the
 window's eventspace.  Every dialog is modal; a dialog's
 @method[dialog% show] method implicitly calls @scheme[yield] to
 handle events while the dialog is shown. (See also
 @secref["espacethreads"] for information about threads and modal
 dialogs.) Furthermore, when a modal dialog is shown, the system
 disables all other top-level windows in the dialog's eventspace, but
 windows in other eventspaces are unaffected by the modal dialog.
 (Disabling a window prevents mouse and keyboard events from reaching
 the window, but other kinds of events, such as update events, are
 still delivered.)


@subsection{Event Types and Priorities}

@section-index["events" "timer"]
@section-index["events" "explicitly queued"]

In addition to events corresponding to user and windowing actions,
 such as button clicks, key presses, and updates, the system
 dispatches two kinds of internal events: @tech{timer events} and
 @tech{explicitly queued events}.

@deftech{Timer events} are created by instances of @scheme[timer%]. When
 a timer is started and then expires, the timer queues an event to
 call the timer's @method[timer% notify] method. Like a top-level
 window, each timer is associated with a particular eventspace (the
 @tech{current eventspace} as described in
 @secref["currenteventspace"]) when it is created, and the timer
 queues the event in its eventspace.

@deftech{Explicitly queued events} are created with
 @scheme[queue-callback], which accepts a callback procedure to handle
 the event. The event is enqueued in the current eventspace at the
 time of the call to @scheme[queue-callback], with either a high or
 low priority as specified by the (optional) second argument to
 @scheme[queue-callback].

An eventspace's event queue is actually a priority queue with events
 sorted according to their kind, from highest-priority (dispatched
 first) to lowest-priority (dispatched last):

@itemize[

 @item{The highest-priority events are high-priority events installed
   with @scheme[queue-callback].}

 @item{Timer events have the second-highest priority.}

 @item{Graphical events, such as mouse clicks or window updates, have
   the second-lowest priority.}

 @item{The lowest-priority events are low-priority events installed
   with @scheme[queue-callback].}

]

Although a programmer has no direct control over the order in which
 events are dispatched, a programmer can control the timing of
 dispatches by setting the event dispatch handler via the
 @scheme[event-dispatch-handler] parameter. This parameter and other
 eventspace procedures are described in more detail in
 @secref["eventspace-funcs"].


@subsection[#:tag "espacethreads"]{Eventspaces and Threads}

When a new eventspace is created, a corresponding @tech{handler
 thread} is created for the eventspace. When the system dispatches an
 event for an eventspace, it always does so in the eventspace's
 handler thread. A handler procedure can create new threads that run
 indefinitely, but as long as the handler thread is running a handler
 procedure, no new events can be dispatched for the corresponding
 eventspace.

When a handler thread shows a dialog, the dialog's @method[dialog%
 show] method implicitly calls @scheme[yield] for as long as the
 dialog is shown. When a non-handler thread shows a dialog, the
 non-handler thread simply blocks until the dialog is
 dismissed. Calling @scheme[yield] with no arguments from a
 non-handler thread has no effect. Calling @scheme[yield] with a
 semaphore from a non-handler thread is equivalent to calling
 @scheme[semaphore-wait].


@subsection[#:tag "currenteventspace"]{Creating and Setting the Eventspace}

Whenever a frame, dialog, or timer is created, it is associated with
 the @deftech{current eventspace} as determined by the
 @scheme[current-eventspace] parameter @|SeeMzParam|.

The @scheme[make-eventspace] procedure creates a new
 eventspace. The following example creates a new eventspace and a new
 frame in the eventspace (the @scheme[parameterize] syntactic form
 temporary sets a parameter value):

@schemeblock[
(let ([new-es (make-eventspace)])
  (parameterize ([current-eventspace new-es])
    (new frame% [label "Example"])))
]

When an eventspace is created, it is placed under the management of
 the @tech[#:doc reference-doc]{current custodian}. When a custodian
 shuts down an eventspace, all frames and dialogs associated with the
 eventspace are destroyed (without calling @method[top-level-window<%>
 can-close?]  or @xmethod[top-level-window<%> on-close]), all timers
 in the eventspace are stopped, and all enqueued callbacks are
 removed.  Attempting to create a new window, timer, or explicitly
 queued event in a shut-down eventspace raises the @scheme[exn:misc]
 exception.

An eventspace is a @techlink[#:doc reference-doc]{synchronizable
 event} (not to be confused with a GUI event), so it can be used with
 @scheme[sync]. As a synchronizable event, an eventspace is in a
 blocking state when a frame is visible, a timer is active, a callback
 is queued, or a @scheme[menu-bar%] is created with a @scheme['root]
 parent. (Note that the blocking state of an eventspace is unrelated
 to whether an event is ready for dispatching.)

@subsection[#:tag "evtcontjump"]{Exceptions and Continuation Jumps}

Whenever the system dispatches an event, the call to the handler
 procedure is wrapped so that full continuation jumps are not allowed
 to escape from the dispatch, and escape continuation jumps are
 blocked at the dispatch site. The following @scheme[block] procedure
 illustrates how the system blocks escape continuation jumps:

@def+int[
(define (block f)
  (code:comment @#,t{calls @scheme[f] and returns void if @scheme[f] tries to escape})
  (let ([done? #f])
    (let/ec k
      (dynamic-wind
        void
        (lambda () (begin0 (f) (set! done? #t)))
        (lambda () (unless done? (k (void))))))))

(block (lambda () 5))
(let/ec k (block (lambda () (k 10))))
(let/ec k ((lambda () (k 10))) 11)
(let/ec k (block (lambda () (k 10))) 11)
]

Calls to the event dispatch handler are also protected with
 @scheme[block].

This blocking of continuation jumps complicates the interaction
 between @scheme[with-handlers] and @scheme[yield] (or the default
 event dispatch handler). For example, in evaluating the expression

@schemeblock[
(with-handlers ([(lambda (x) #t)
                 (lambda (x) (error "error during yield"))])
   (yield))
]

the @scheme["error during yield"] handler is @italic{never} called,
 even if a callback procedure invoked by @scheme[yield] raises an
 exception.  The @scheme[with-handlers] expression installs an
 exception handler that tries to jump back to the context of the
 @scheme[with-handlers] expression before invoking a handler
 procedure; this jump is blocked by the dispatch within
 @scheme[yield], so @scheme["error during yield"] is never
 printed. Exceptions during @scheme[yield] are ``handled'' in the
 sense that control jumps out of the event handler, but @scheme[yield]
 may dispatch another event rather than escaping or returning.

The following expression demonstrates a more useful way to handle
 exceptions within @scheme[yield], for the rare cases where
 such handling is useful:

@schemeblock[
(let/ec k
  (call-with-exception-handler
   (lambda (x)
     (error "error during yield")
     (k))
   (lambda ()
     (yield))))
]

This expression installs an exception handler that prints an error
 message @italic{before} trying to escape. Like the continuation escape
 associated with @scheme[with-handlers], the escape to @scheme[k] never
 succeeds.  Nevertheless, if an exception is raised by an event
 handler during the call to @scheme[yield], an error message is
 printed before control returns to the event dispatcher within
 @scheme[yield].
