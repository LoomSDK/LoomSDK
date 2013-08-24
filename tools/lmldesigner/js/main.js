$(function () {
    log("DOM Ready. Please select your aspect ratio and window size before adding objects to the scene. The editor does not yet support scene recalculation on window resize.");

    // get the art directory
    var qs = (window.location.href.toString().split('#'));
    var artdir = decodeURIComponent(typeof qs[1] == 'undefined' ? "" : qs[1]);

    // if this is a save, clear up object borders
    $(".entity").css("border", "");

    // load the path if it has been saved
    if ($("#projectpath-save").text().trim() != "" && $("#projectpath-save").text().trim() != "/")
        $("#projectpath").val($("#projectpath-save").text());

    if (typeof artdir == 'undefined' || artdir == null || artdir == "" || artdir == "/") {
        // try the input on the page - maybe this has been saved and is being loaded back
        artdir = $("#projectpath").val();

        if (typeof artdir == 'undefined' || artdir == null || artdir == "" || artdir == "/") {
            artdir = window.prompt("Please enter the directory where your art assets reside.", "");
            window.location.href = qs[0] + "#" + encodeURIComponent((artdir));
        }
    }
    artdir = artdir.split("\\").join('/');
    if (artdir.substr(-1, 1) == "/")
        artdir = artdir.substr(0, artdir.length - 1);
    $("input#projectpath").val(artdir + "/");
    $("#projectpath-save").text(artdir + "/");

    var aspect = $("option:selected", this).val().split("x");
    $$ = new LMLScene($("#layer"), aspect[0], aspect[1]);

    $$.editing = false;
    $$.updatePropertyEditor();

    updateImagePool();
    initDragDrop();

    // press shift to lock onto an axis
    $(document).keydown(function (e) {
        $$.shiftPressed = e.shiftKey;
        if (e.keyCode >= 48 && e.keyCode <= 57) {
            var key = e.keyCode - 48;
            $(".entity.selected").each(function () {
                var data = $("div.data > div[data-view-name='" + $$.getActiveView() + "']", $(this));
                if ($$.shiftPressed) {
                    // shift + number -> set duration
                    data.attr('data-duration', (key * 0.1).toFixed(3));
                    $("#entity-duration").val(data.attr('data-duration')).fadeTo(50, 0.2).fadeTo(50, 1).fadeTo(50, 0.2).fadeTo(50, 1).fadeTo(50, 0.2).fadeTo(50, 1);
                } else {
                    // number -> set delay
                    data.attr('data-delay', (key * 0.1).toFixed(3));
                    $("#entity-delay").val(data.attr('data-delay')).fadeTo(50, 0.2).fadeTo(50, 1).fadeTo(50, 0.2).fadeTo(50, 1).fadeTo(50, 0.2).fadeTo(50, 1);
                }
            });
        } else if (e.keyCode == 37) { // left
            $(".entity.selected").each(function () {
                var data = $("div.data > div[data-view-name='" + $$.getActiveView() + "']", $(this));
                data.attr('data-coords-x', data.attr('data-coords-x') * 1 - ($$.shiftPressed ? 16 : 1));
                var lcoords = { x: data.attr('data-coords-x'), y: data.attr('data-coords-y') };
                var vcoords = $$.loomToScreenCoords(lcoords, $(this).width(), $(this).height());
                $(this).css({
                    left: vcoords.x + "px",
                    top: vcoords.y + "px"
                });
            });
        } else if (e.keyCode == 38) { // up
            $(".entity.selected").each(function () {
                var data = $("div.data > div[data-view-name='" + $$.getActiveView() + "']", $(this));
                data.attr('data-coords-y', data.attr('data-coords-y') * 1 + ($$.shiftPressed ? 16 : 1));
                var lcoords = { x: data.attr('data-coords-x'), y: data.attr('data-coords-y') };
                var vcoords = $$.loomToScreenCoords(lcoords, $(this).width(), $(this).height());
                $(this).css({
                    left: vcoords.x + "px",
                    top: vcoords.y + "px"
                });
            });
        } else if (e.keyCode == 39) { // right
            $(".entity.selected").each(function () {
                var data = $("div.data > div[data-view-name='" + $$.getActiveView() + "']", $(this));
                data.attr('data-coords-x', data.attr('data-coords-x') * 1 + ($$.shiftPressed ? 16 : 1));
                var lcoords = { x: data.attr('data-coords-x'), y: data.attr('data-coords-y') };
                var vcoords = $$.loomToScreenCoords(lcoords, $(this).width(), $(this).height());
                $(this).css({
                    left: vcoords.x + "px",
                    top: vcoords.y + "px"
                });
            });
        } else if (e.keyCode == 40) { // down
            $(".entity.selected").each(function () {
                var data = $("div.data > div[data-view-name='" + $$.getActiveView() + "']", $(this));
                data.attr('data-coords-y', data.attr('data-coords-y') * 1 - ($$.shiftPressed ? 16 : 1));
                var lcoords = { x: data.attr('data-coords-x'), y: data.attr('data-coords-y') };
                var vcoords = $$.loomToScreenCoords(lcoords, $(this).width(), $(this).height());
                $(this).css({
                    left: vcoords.x + "px",
                    top: vcoords.y + "px"
                });
            });
        }
        return true;
    });

    // delete selected via del key
    $(document).keyup(function (e) {
        $$.shiftPressed = e.shiftKey;
        if (e.keyCode == 46) {
            $(".entity.selected").each(function () {
                if (confirm("Are you sure you want to delete that object?") == true) {
                    $(this).remove();
                }
            });
        }
        return true;
    });

    // resize the scene when the window is resized
    $(window).on("resize", function () {
        var selval = $("select#size option:selected").val();
        var aspect = selval.split("x");
        $$.updateSize(aspect[0], aspect[1]);
    });

    if ($("#projectname-save").text().trim() != "")
        $("#projectname").val($("#projectname-save").text());

    if ($("#size-save").text().trim() != "")
        $("#size").val($("#size-save").text());

    // resize when the mode and aspect ratio is changed
    $("#size").on("change",function () {
        $(window).trigger("resize");
        $("#size-save").text($("select#size option:selected").val());
    }).trigger("change");

    // sanitize the project path value
    $("#projectpath").on("blur", function () {
        var val = $(this).val().split("\\").join('/');
        if (val.substr(-1, 1) == "/")
            val = val.substr(0, val.length - 1);
        $(this).val(val + "/");
    });

    // save the project path as the input changes
    $("#projectpath").on("change keyup blur",function () {
        $("#projectpath-save").text($(this).val());
        window.location.href = qs[0] + "#" + encodeURIComponent(($(this).val()));
    }).trigger('change');
    //save the project name
    $("#projectname").on("change keydown blur",function () {
        $("#projectname-save").text($(this).val());
    }).trigger('change');

    // remove all resizable ui divs
    $(".ui-resizable-handle").remove();
    // if this is a saved document, we need to re-register drag, resize and hover events on existing objects
    $(".entity").each(function () {
        var entity = $(this);

        // reposition the image in the dom
        var img = $(".ui-wrapper", entity).html();
        $(".ui-wrapper", entity).remove();
        entity.append(img);

        // register handlers for resize, hover and drag
        $$.registerResize(entity);
        $$.registerHover(entity);
        $$.registerDrag(entity);
    });

    $("#addview").on("click", function () {
        var keyname = prompt("Name your new view", "");
        $$.addView(keyname);
        $$.bindViewClicks();
    });

    if ($$.getViewCount() == 0) {
        $$.addView("__root", false);
        log("Use the special '__root' view to plan a UI with initial and between-views properties. Usually, objects are hidden or moved away from the visible area in this view.");
    }

    $$.bindViewClicks();

    // opacity change via the mousewheel
    $("div.entity").each(function(){
        var entity = $(this);
        var img = $("img", entity);
        img.mousewheel(function(event, delta){
            $$.handleMouseWheel(entity, delta);
        }).dblclick(function () {
            $$.handleDoubleClick();
        });
    });

    $$.onActiveViewChange();

    // bind the export button
    $(".export button").on("click", function () {
        $$.export();
    });

    // bind the export results window close button
    $("div#downloads > div > button").on("click", function () {
        $("div#downloads").fadeOut();
    });
});
// can refer to the global LML scene as $$

Window.prototype.updateImagePool = function () {
    $$.resizing = false;
    $$.dragging = false;
    // register a click view on these
    var imgs = $("ul#imagepool li");
    imgs.unbind("click");
    imgs.on("click", function () {
        if ($$.getViewCount() <= 0) {
            log("You need to add an view to the scene before you can add an object instance to the current view.", "error");
            $("#addview").trigger("click");
            //return;
        }
        var li = $(this);
        var img = $("img", li);
        var id = $$.addEntity(img.attr("src"), img.attr("title"));

        var entity = $("#" + id);

        $$.registerResize(entity);
        $$.registerHover(entity);
        $$.registerDrag(entity);
    });
};

// The following snippet is from http://stackoverflow.com/questions/105034/how-to-create-a-guid-uuid-in-javascript
// and was posted by broofa (www.broofa.com)
Window.prototype.guid = function () {
    return 'guid_xxxxxxxx_xxxx_4xxx_yxxx_xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
        var r = Math.random() * 16 | 0, v = c == 'x' ? r : (r & 0x3 | 0x8);
        return v.toString(16);
    });
};

Window.prototype.log = function (message, style) {
    if (typeof style != "undefined") {
        style = " class='" + style + "'";
    } else {
        style = "";
    }
    var target = $(".log > div");
    target.append("<pre" + style + ">&gt; " + message + "</pre>");
    $(".log")[0].scrollTop = $(".log")[0].scrollHeight;
    if (style != "")
        $(".log > div pre:last-child").fadeIn("fast").fadeOut("fast").fadeIn("fast").fadeOut("fast").fadeIn("fast").fadeOut("fast").fadeIn("fast");
};

Window.prototype.initDragDrop = function () {
    // Setup the drag and drop over the entire document
    $("html").on("dragover", function(evt){
        evt.stopPropagation();
        evt.preventDefault();
        evt.originalEvent.dataTransfer.dropEffect = 'copy'; // Explicitly show this is a copy.
    }).on("drop", function(evt){
        evt.stopPropagation();
        evt.preventDefault();

        var files = evt.originalEvent.dataTransfer.files; // FileList object.

        for (var i = 0, f; f = files[i]; i++) {
            var img = new Image();
            $(img).load({ img: img, file_name: f.name }, function(event) {
                var img = event.data.img;
                var file_name = event.data.file_name;

                img.title = file_name.toCamelCaseVariable().stripExtension();
                $(img).attr('data-use-counter', "0");

                var li = document.createElement("li");
                li.appendChild(img);
                $(li).append('<div>' + file_name + '</div>');

                $("#imagepool").append('<li>' + $(li).html() + '</li>');
                log("Successfully added '" + file_name + "' to the image pool.");

                updateImagePool();

            }).error({ file_name: f.name }, function(event){
                    log("The image '" + event.data.file_name + "' is not in the '" + $("#projectpath-save").text() + "' directory.\n  Please check your path setup and make sure all your images reside in that directory.", "error");
                    $(this).remove();
                });
            img.src = 'file:///' + $("#projectpath").val() + f.name;
        }
    });
};

String.prototype.toCamelCaseVariable = function () {
    return this.replace(/[-_ ]+([a-z])/g, function (g) {
        return g[1].toUpperCase()
    });
};

String.prototype.stripExtension = function () {
    return this.replace(/\.[^/.]+$/, "");
};

String.prototype.capitalize = function () {
    return this.charAt(0).toUpperCase() + this.slice(1);
};
