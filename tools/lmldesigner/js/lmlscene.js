function LMLScene(layerObject, w, h) {
    var self = this;

    var templates = this.fetchTemplates();

    self.lsTemplate = templates.ls;
    self.lmlTemplate = templates.lml;
    self.configTemplate = templates.config;

    self.rect = { x: 0, y: 0, w: 0, h: 0 };
    self.layer = layerObject;
    self.updateSize(w, h);
}

LMLScene.prototype.onActiveViewChange = function () {
    var self = this;

    var view_name = this.getActiveView();
    if (view_name != null) {
        //log("Selected view '"+view_name+"'.");
        $("#view").text(view_name).fadeIn();
    }

    var entityList = $(".entity");

    // get the object in this view that will animate the longest
    var longestAnimEntity = null;
    var longestAnimSecs = 0;
    entityList.each(function () {
        var entity = $(this);
        var data = $("div.data > div[data-view-name='" + view_name + "']", entity);
        var animSecs = data.attr("data-duration") * 1 + data.attr("data-delay") * 1;
        if (longestAnimSecs == null || animSecs > longestAnimSecs) {
            longestAnimSecs = animSecs;
            longestAnimEntity = entity.attr("id");
        }
    });

    // if we have a longest anim value, add that to the view's properties
    if (longestAnimEntity != null) {
        $("div#views div.view[data-view-name='" + view_name + "']").attr('data-longest-animating', longestAnimEntity);
    }

    // assign transition settings to all entities that are not currently selected
    entityList.each(function () {
        if ($(this).hasClass("selected"))
            return;

        var entity = $(this);
        var data = $("div.data > div[data-view-name='" + view_name + "']", entity);

        var lcoords = {x: data.attr("data-coords-x"), y: data.attr("data-coords-y")};
        var width = data.attr("data-width");
        var height = data.attr("data-height");
        var opacity = data.attr("data-opacity");
        var coords = self.loomToScreenCoords(lcoords, width, height);

        var easing = data.attr("data-easing");
        var duration = data.attr("data-duration");
        var delay = data.attr("data-delay");

        var must_export = data.attr("data-export") == "1" || view_name == "__root";

        var chkbox = $(".chk > input[type='checkbox']", entity);

        entity.css({
            width: "auto",
            height: "auto",
            border: "1px dashed rgba(255,255,0,0)",
            position: "fixed"
        });

        $(".ui-resizable-handle", entity).fadeOut(0);
        chkbox.hide();

        $("#layer").addClass('animating');

        entity.delay(delay * 1000).animate({
            left: coords.x + 'px',
            top: coords.y + 'px'
        }, {
            easing: easing,
            duration: duration * 1000,
            always: function () {
                entity.css({
                    border: "1px dashed rgba(255,255,0,1)"
                });

                // update checkbox for the object in the new view
                if (view_name == "__root") {
                    chkbox.hide();
                } else {
                    chkbox.show();
                }

                if (must_export) {
                    chkbox.prop("checked", true);
                } else {
                    chkbox.prop("checked", false);
                }

                // mark the transition complete on the layer if this is the last object to finish
                $(".ui-resizable-handle", entity).fadeIn(500);
                if (longestAnimEntity != null && longestAnimEntity == entity.attr('id')) {
                    $("#layer").removeClass('animating');
                }
            }
        });

        $("img", entity).delay(delay * 1000).animate({
            width: width + "px",
            height: height + "px",
            opacity: data.attr("data-opacity")
        }, {
            easing: easing,
            duration: duration * 1000
        });

        $("img", entity).parent().css({
            width: "auto",
            height: "auto"
        });

        self.selectEntity(entity.attr('id'), false);
    });

};

LMLScene.prototype.getViewCount = function () {
    return $(".view").length;
};

LMLScene.prototype.removeView = function (name) {
    $("div.data > div[data-view-name='" + name + "']").remove();
};

LMLScene.prototype.duplicateView = function (target, newname) {
    $(".entity").each(function () {
        var entity = $(this);
        var data = $("div.data > div[data-view-name='" + target + "']", entity).clone();
        data.attr("data-view-name", newname);
        data.attr("data-export", "1");
        var outerhtml = $("<div />").append(data).html();
        $(".data", entity).append(outerhtml);
        // make the checkbox visible and checked by default
        $(".chk > input[type='checkbox']", entity).prop("checked", true).show();
    });
};

LMLScene.prototype.addView = function (keyname, canclose) {
    if (typeof canclose == 'undefined')
        canclose = true;

    if (keyname != null && keyname.trim() != "") {
        // check if there is an view with this name already
        if ($("div[data-view-name='" + keyname + "']").length > 0) {
            log("ERROR: An view with the name '" + keyname + "' already exists.", "error");
            return;
        }
        // check if there is already an active view - if there is one, duplicate that with a new name
        // update: let's duplicate __root instead
        if (this.getActiveView() != null) {
            //this.duplicateView(this.getActiveView(), keyname);
            this.duplicateView("__root", keyname);
        }

        // add the view button
        $("div#views > div.view").removeClass("active");
        $("#views").append("<div class='view active' data-view-name='" + keyname + "'>" + keyname + " " + (canclose ? "<span class='close'>&times;</span>" : "") + "</div>");
        log("New view '" + keyname + "' added.");

        this.onActiveViewChange();
    }
};

LMLScene.prototype.selectEntity = function (id, realSelect) {
    if (typeof realSelect == 'undefined')
        realSelect = true;

    var self = this;

    self.deselectEntities();
    var entity = $("#" + id);
    var data = $("div.data > div[data-view-name='" + self.getActiveView() + "']", entity);

    if (realSelect) {
        entity.addClass("selected");
    }

    self.lastSelectedEntity = id;

    var checkbox = $(".chk > input[type='checkbox']");
    checkbox.unbind('change').bind('change', function () {
        data.attr('data-export', $(this).is(':checked') ? "1" : "0");
    });

    $("#entity-id").text(id);

    $("#entity-apply").unbind('click').bind('click', function () {
        self.editing = false;
        self.updatePropertyEditor();
    });

    // copy entity values into the property editor and propagate changes back
    $("#entity-name").val(entity.attr('data-name')).unbind('change').bind('change', function (event) {
        entity.attr("data-name-edited", "1");
        entity.attr('data-name', $(this).val());
        if (event.which == 13) {
            self.editing = false;
            self.updatePropertyEditor();
        }
    });

    $("#entity-class").val(entity.attr('data-class')).unbind('change').bind('change', function (event) {
        entity.attr("data-class-edited", "1");
        entity.attr('data-class', $(this).val());
        if (event.which == 13) {
            self.editing = false;
            self.updatePropertyEditor();
        }
    });

    $("#entity-duration").val(data.attr('data-duration')).unbind('change').bind('change', function (event) {
        data.attr('data-duration', $(this).val());
        if (event.which == 13) {
            self.editing = false;
            self.updatePropertyEditor();
        }
    });
    $("#entity-delay").val(data.attr('data-delay')).unbind('change').bind('change', function (event) {
        data.attr('data-delay', $(this).val());
        if (event.which == 13) {
            self.editing = false;
            self.updatePropertyEditor();
        }
    });
    $("#entity-position-x").val(data.attr('data-coords-x')).unbind('change').bind('change', function (event) {
        data.attr('data-coords-x', $(this).val());
        var lcoords = { x: data.attr('data-coords-x'), y: data.attr('data-coords-y') };
        var vcoords = $$.loomToScreenCoords(lcoords, entity.width(), entity.height());
        entity.css({
            left: vcoords.x + "px",
            top: vcoords.y + "px"
        });
        if (event.which == 13) {
            self.editing = false;
            self.updatePropertyEditor();
        }
    });
    $("#entity-position-y").val(data.attr('data-coords-y')).unbind('change').bind('change', function (event) {
        data.attr('data-coords-y', $(this).val());
        var lcoords = { x: data.attr('data-coords-x'), y: data.attr('data-coords-y') };
        var vcoords = $$.loomToScreenCoords(lcoords, entity.width(), entity.height());
        entity.css({
            left: vcoords.x + "px",
            top: vcoords.y + "px"
        });
        if (event.which == 13) {
            self.editing = false;
            self.updatePropertyEditor();
        }
    });
    $("#entity-easetype").val(data.attr('data-easing')).unbind('change').bind('change', function () {
        data.attr('data-easing', $("option:selected", $(this)).val());
        data.attr('data-easing-loom', $("option:selected", $(this)).text())
    });

    $("#entity-scale").unbind('change').bind('change', function () {
        var img = $("img", entity);
        var owidth = img.attr("data-original-width");
        var oheight = img.attr("data-original-height");
        var nscale = $(this).val();

        data.attr("data-scale", nscale);
        data.attr("data-width", nscale * owidth);
        data.attr("data-height", nscale * oheight);

        // rescale the image
        img.width(nscale * owidth);
        img.height(nscale * oheight);

        var lcoords = { x: data.attr("data-coords-x"), y: data.attr("data-coords-y") };
        var coords = self.loomToScreenCoords(lcoords, nscale * owidth, nscale * oheight);
        entity.css({
            left: coords.x + "px",
            top: coords.y + "px"
        });
    });

    $("#entity-opacity").val(data.attr('data-opacity') * 100).unbind('change').bind('change', function () {
        data.attr('data-opacity', $(this).val() / 100);
        $("img", entity).fadeTo(0, $(this).val() / 100);
    });
};

LMLScene.prototype.deselectEntities = function () {
    $(".entity").removeClass("selected");
};

LMLScene.prototype.updatePropertyEditor = function () {
    if (!this.editing) {
        $(".entity-properties select, .entity-properties input, .entity-properties button").attr("disabled", "disabled");
        $(".entity").removeClass("editing");
        $(".entity-properties").fadeTo(200, 0.5);
    } else {
        $(".entity-properties select, .entity-properties input, .entity-properties button").removeAttr("disabled");
        $(".entity-properties").fadeTo(50, 0.2).fadeTo(50, 1).fadeTo(50, 0.2).fadeTo(50, 1).fadeTo(50, 0.2).fadeTo(50, 1);
        $("#" + $("#entity-id").text()).addClass("editing").fadeTo(50, 0.2).fadeTo(50, 1).fadeTo(50, 0.2).fadeTo(50, 1).fadeTo(50, 0.2).fadeTo(50, 1);
        this.deselectEntities();
    }
};

LMLScene.prototype.handleMouseWheel = function(entity, delta)
{
    var img = $("img", entity);
    var opacity = $(img).css("opacity");
    opacity = opacity * 1 + delta * 0.05;
    opacity = Math.min(1, Math.max(0, opacity));
    $(img).fadeTo(0, opacity);
    var data = $("div.data > div[data-view-name='" + this.getActiveView() + "']", entity);
    data.attr("data-opacity", opacity);
    $("#entity-opacity").val(opacity * 100);
};

LMLScene.prototype.handleDoubleClick = function()
{
    if (this.editing) {
        this.editing = false;
        this.updatePropertyEditor();
        return;
    }
    this.editing = true;
    $("#entity-name").focus()[0].select();
    this.updatePropertyEditor();
};

LMLScene.prototype.addEntity = function (src, varname) {
    var self = this;

    var id = guid();
    var poolImg = $("ul#imagepool img[title='" + varname + "']");
    var varnameCounter = poolImg.attr('data-use-counter') * 1 + 1;

    varname = varname + varnameCounter; //+id.split('_').join('').split('guid').join('').substr(0, 4)
    poolImg.attr('data-use-counter', varnameCounter);

    this.layer.append('<div id="' + id + '" data-name="' + varname + '" data-class="cocos2d.CCSprite" class="entity"><div class="data"></div><div class="chk"><input type="checkbox" title="Check to export this object for the current view." checked="checked"></div></div>');


    $("div#views > div.view").each(function () {
        $("div.data", $("#" + id)).append("<div data-view-name='" + $(this).attr('data-view-name') + "' data-export='1' data-coords-x='" + (self.virtualSize.w / 2) + "' data-coords-y='" + (self.virtualSize.h / 2) + "' data-opacity='1' data-width='' data-height='' data-duration='0.3' data-delay='0' data-scale='1' data-easing='easeInOutBack' data-easing-loom='EaseType.EASE_IN_OUT_BACK'></div>");
    });

    var img = new Image();
    $(img).bind('load', function () {
        var entity = $("#" + id);
        $(img).attr("data-original-width", $(img).width() * self.globalScale);
        $(img).attr("data-original-height", $(img).height() * self.globalScale);
        $(".data > div", entity).attr("data-width", $(img).width() * self.globalScale);
        $(".data > div", entity).attr("data-height", $(img).height() * self.globalScale);

        // update initial width and height based on the virtual scale
        $(img).width($(img).width() * self.globalScale);
        $(img).height($(img).height() * self.globalScale);

        // opacity change via the mousewheel
        $(img).mousewheel(function(event, delta){
            self.handleMouseWheel(entity, delta);
        }).dblclick(function () {
            self.handleDoubleClick();
        }).width(20).height(20);

        // this will update the position of the new entity to 0:0
        self.onActiveViewChange();

        self.selectEntity(id);
    });
    img.src = src;
    $("#" + id)[0].appendChild(img);

    return id;
};

LMLScene.prototype.getActiveView = function () {
    var active = $("div#views div.view.active");
    return active.length > 0 ? active.first().attr("data-view-name") : null;
};

LMLScene.prototype.updateSize = function (aspect_x, aspect_y) {
    var self = this;

    var mustRescale = typeof self.virtualSize != 'undefined';

    self.prevScreen = {
        aspect: self.aspect,
        workArea: self.workArea,
        mode: self.mode,
        rect: self.rect,
        virtualSize: self.virtualSize,
        globalScale: self.globalScale
    };

    self.aspect = { x: aspect_x, y: aspect_y };
    self.workArea = { w: $(window).width() * 0.8 | 0, h: $(window).height() * 0.9 | 0 };

    self.mode = "portrait";
    if (aspect_x > aspect_y) self.mode = "landscape";

    var w = 0;
    var h = 0;
    var vw = 0;
    var vh = 0;
    var maxw = 0;
    var maxh = 1920;

    if (aspect_x > 100 && aspect_x < self.workArea.w * 0.8 && aspect_y > 100 && aspect_y < self.workArea.h * 0.8) {
        // actual dimensions
        w = aspect_x;
        vw = aspect_x;
        h = aspect_y;
        vh = aspect_y;

        if (aspect_x * 1 < aspect_y * 1) {
            aspect_y = (aspect_y / aspect_x);
            aspect_x = 1;
        } else {
            aspect_x = (aspect_x / aspect_y);
            aspect_y = 1;
        }
    } else {
        if (aspect_x * 1 > 100 || aspect_y * 1 > 100) {
            maxw = aspect_x;
            maxh = aspect_y;

            if (aspect_x * 1 < aspect_y * 1) {
                aspect_y = (aspect_y / aspect_x);
                aspect_x = 1;
            } else {
                aspect_x = (aspect_x / aspect_y);
                aspect_y = 1;
            }
        }
        // aspect ratio only
        // on-screen size
        while (w < self.workArea.w / 1.44 && h < self.workArea.h / 1.44) {
            w += aspect_x * 1;
            h += aspect_y * 1;
        }

        // virtual resolution
        while (vw < maxw && vh < maxh) {
            vw += aspect_x * 1;
            vh += aspect_y * 1;
        }
    }

    var changed = false;
    if (self.rect.w != w || self.rect.h != h)
        changed = true;

    self.rect = { x: (self.workArea.w / 2 - w / 2) | 0, y: (self.workArea.h / 2 - h / 2) | 0, w: w | 0, h: h | 0 };

    self.virtualSize = { w: vw, h: vh };
    self.globalScale = (self.rect.w / self.virtualSize.w);
    var scaleDir = "";
    if (self.globalScale > 1) {
        scaleDir = " up";
    } else if (self.globalScale < 1) {
        scaleDir = " down";
    }

    if (changed)
        log("Aspect ratio set to " + (((aspect_x * 100) | 0) / 100) + ":" + (((aspect_y * 100) | 0) / 100) + " in " + self.mode + " mode with a virtual resolution of " + (self.virtualSize.w | 0) + ":" + (self.virtualSize.h | 0) + " scaled" + scaleDir + " to " + (self.globalScale * 100 | 0) + "%.");

    self.layer.css({
        left: self.rect.x + "px",
        top: self.rect.y + "px",
        width: self.rect.w + "px",
        height: self.rect.h + "px"
    });

    // if this has been a rescale, we will need to go over all objects in the scene and rescale / reposition them
    // this is only partially written and buggy but this is going to be able to recalculate the scene on a
    // window and/or project resize. I didn't want to remove what I've already written, but this is probably not
    // going to be a feature until I can spend some additional time on it. I'll keep it commented out for now.
    // -- konrad
    /*
    if (mustRescale) {

        var wScale = self.virtualSize.w / self.prevScreen.virtualSize.w;
        var hScale = self.virtualSize.h / self.prevScreen.virtualSize.h;

        var objScale = hScale;
        if (hScale < wScale) objScale = wScale;

        $(".entity").each(function () {
            var entity = $(this);
            $(".data > div", entity).each(function () {

                // find new coords and scale
                var pos_x = Math.round($(this).attr('data-coords-x') * wScale);
                var pos_y = Math.round($(this).attr('data-coords-y') * hScale);
                var scale = ($(this).attr('data-scale') * objScale).toFixed(3);

                // update the dom db
                $(this).attr('data-coords-x', pos_x);
                $(this).attr('data-coords-y', pos_y);
                $(this).attr('data-scale', scale);

                // update the scene
                $("#entity-position-x").val(pos_x).trigger('change');
                $("#entity-position-y").val(pos_y).trigger('change');
                $("#entity-scale").val(scale).trigger('change');
            });
        });
    }
    */
};

LMLScene.prototype.bindViewClicks = function () {
    var self = this;

    var viewList = $("div#views div.view");

    $(".close", viewList).unbind('click');
    $(".close", viewList).on("click", function () {
        if (confirm("Are you sure you want to remove that view?") == true) {
            log("Removing view '" + $(this).parent().attr("data-view-name") + "'.", "error");
            self.removeView($(this).parent().attr("data-view-name"));
            if ($(this).parent().hasClass("active")) {
                var selected = $(".view", $(this).parent().parent()).first();
                selected.addClass("active");
                self.onActiveViewChange();
            }
            $(this).parent().remove();
        }
    });

    viewList.unbind('click');
    viewList.on("click", function () {
        if (self.editing) {
            log("You can not change views while editing an object. First double-click an object to leave edit mode.", "error");
            return;
        }
        // clicking the view must make this view active
        viewList.removeClass("active");
        $(this).addClass("active");
        self.onActiveViewChange();
    });
};

LMLScene.prototype.registerResize = function (entity) {
    var self = this;

    // resize
    $("img", entity).resizable({
        aspectRatio: true,
        //handles: "se",
        start: function () {
            self.resizing = true;
        },
        stop: function () {
            var datastore = $(".data div[data-view-name='" + self.getActiveView() + "']", entity);
            datastore.attr("data-width", $("img", entity).width());
            datastore.attr("data-height", $("img", entity).height());

            self.resizing = false;
            self.deselectEntities();
        },
        resize: function () {
            self.resizing = true;
            // make sure the entity stays on the same loom coordinates
            var datastore = $(".data div[data-view-name='" + self.getActiveView() + "']", entity);
            var lcoords = { x: datastore.attr("data-coords-x"), y: datastore.attr("data-coords-y") };
            var coords = self.loomToScreenCoords(lcoords, $(this).width(), $(this).height());
            entity.css({
                left: coords.x + "px",
                top: coords.y + "px"
            });
            var owidth = $("img", entity).attr("data-original-width");
            var scale = ((($(this).width() / owidth) * 100) | 0) / 100;
            $("#entity-scale").val(scale);
            datastore.attr("data-scale", scale);
            datastore.attr("data-width", $(this).width());
            datastore.attr("data-height", $(this).height());
            $("img", entity).css({
                width: $(this).width(),
                height: $(this).height()
            });
        }
    });
};

LMLScene.prototype.registerHover = function (entity) {
    var self = this;

    // select / deselect on mouseenter / mouseleave
    entity.hover(function () {
        if (self.resizing || self.dragging || self.editing)
            return;
        self.selectEntity($(this).attr("id"));
    }, function () {
        if (self.resizing || self.dragging || self.editing)
            return;
        self.deselectEntities();
    });
};

LMLScene.prototype.registerDrag = function (entity) {
    var self = this;

    // drag
    entity.draggable({
        distance: 5,
        drag: function (event, ui) {
            self.dragging = true;

            var coords = { x: entity.offset().left, y: entity.offset().top };

            // shift will lock onto an axis
            var dragDelta = { x: Math.abs(ui.position.left - self.dragStartCoords.x), y: Math.abs(ui.position.top - self.dragStartCoords.y) };
            if (self.shiftPressed) {
                if (dragDelta.x > dragDelta.y) {
                    ui.position.top = self.dragStartCoords.y;
                } else {
                    ui.position.left = self.dragStartCoords.x;
                }
                entity.css({
                    left: ui.position.left + "px",
                    top: ui.position.top + "px"
                });
            }

            // get loom coords
            var loomcoords = self.screenToLoomCoords(coords, entity.width(), entity.height());
            var datastore = $(".data div[data-view-name='" + self.getActiveView() + "']", $(this));
            datastore.attr("data-coords-x", loomcoords.x);
            datastore.attr("data-coords-y", loomcoords.y);
            $("#entity-position-x").val(loomcoords.x);
            $("#entity-position-y").val(loomcoords.y);
        },
        start: function (event, ui) {
            self.dragging = true;
            self.dragStartCoords = { x: ui.position.left, y: ui.position.top };
        },
        stop: function () {
            self.dragging = false;
            self.deselectEntities();
        }
    });
};

LMLScene.prototype.loomToScreenCoords = function (coords, width, height) {
    width = typeof width == 'undefined' ? 0 : width * 1;
    height = typeof height == 'undefined' ? 0 : height * 1;
    var loomO = { x: this.rect.x * 1, y: this.rect.y * 1 + this.rect.h * 1 };
    coords.x *= this.globalScale;
    coords.y *= this.globalScale;
    var res = { x: (coords.x * 1 + loomO.x * 1), y: (loomO.y * 1 - coords.y * 1) };
    res.x -= width / 2;
    res.y -= height / 2;
    return { x: Math.round(res.x), y: Math.round(res.y) };
};

LMLScene.prototype.screenToLoomCoords = function (coords, width, height) {
    width = typeof width == 'undefined' ? 0 : width * 1;
    height = typeof height == 'undefined' ? 0 : height * 1;
    coords.x += width / 2;
    coords.y += height / 2;
    var loomO = { x: this.rect.x * 1, y: this.rect.y * 1 + this.rect.h * 1 };
    var res = { x: -(loomO.x * 1 - coords.x * 1), y: (loomO.y * 1 - coords.y * 1) };
    res.x /= this.globalScale;
    res.y /= this.globalScale;
    return { x: Math.round(res.x), y: Math.round(res.y) };
};

LMLScene.prototype.export = function () {
    var self = this;

    log("Exporting data...");

    var viewList = $("div#views > div.view");
    var entityList = $(".entity");

    var project_name = $("#projectname").val().trim();

    if (project_name == "") {
        log("Please set the project name before you export your views.", "error");
        return false;
    }
    if (entityList.length == 0) {
        log("You don't have any objects added to your views.", "error");
        return false;
    }
    if (viewList.length < 2) {
        log("You need to add at least one view to the scene.", "error");
        return false;
    }

    // clear links
    $("#links").html('');

    // export the config file
    var export_config = self.configTemplate;
    export_config = export_config
        .replace(/\%project_name\%/g, project_name)
        .replace(/\%virtual_width\%/g, $$.virtualSize.w + "")
        .replace(/\%virtual_height\%/g, $$.virtualSize.h + "");
    //$$.addDownloadLink("loom.config", base64_encode(export_config)); -- disabled temporarily until this gets a separate ui

    // got through all views
    viewList.each(function () {
        var view = $(this);

        var view_name = view.attr("data-view-name");
        if (view_name == "__root")
            return;

        var capital_viewname = view_name.capitalize();
        var lower_viewname = view_name.toLowerCase();

        var export_ls = self.lsTemplate;
        var export_lml = self.lmlTemplate;

        var import_list = {};
        var imports = "";
        var vars = "";
        var destroys = "";
        var exit_setup = "";
        var tweens = "";
        var exit_tweens = "";

        var lml_nodes = "";

        var longest_animating = view.attr('data-longest-animating');
        var root_longest_animating = $("div#views > div.view[data-view-name='root']").attr('data-longest-animating');

        // for every view other than the root view, go through all objects
        entityList.each(function () {
            var entity = $(this);
            var data = $("div.data > div[data-view-name='" + view_name + "']", entity);
            var root_data = $(".data div[data-view-name='__root']", entity);

            // skip if this object doesn't need to be exported for this view
            if (data.attr("data-export") != "1")
                return;

            // set up basic template variables
            var object_name = entity.attr("data-name");
            var object_class_ns = entity.attr("data-class");
            var object_class = object_class_ns.split('.');
            object_class = object_class[object_class.length - 1];
            var pos_x = (data.attr('data-coords-x') * 1).toFixed(0);
            var pos_y = (data.attr('data-coords-y') * 1).toFixed(0);
            var scale = (data.attr('data-scale') * 1).toFixed(3);
            var opacity = (data.attr('data-opacity') * 1).toFixed(3);
            var easing = data.attr('data-easing-loom');
            var duration = (data.attr('data-duration') * 1).toFixed(3);
            var delay = (data.attr('data-delay') * 1).toFixed(3);

            var img = $("img", entity).first();
            var img_src = img.attr('src');
            var texture_name = img_src.substr(img_src.lastIndexOf('/') + 1);

            // read initial / exit values
            var root_pos_x = (root_data.attr('data-coords-x') * 1).toFixed(0);
            var root_pos_y = (root_data.attr('data-coords-y') * 1).toFixed(0);
            var root_scale = (root_data.attr('data-scale') * 1).toFixed(3);
            var root_opacity = (root_data.attr('data-opacity') * 1).toFixed(3);
            var root_easing = root_data.attr('data-easing-loom');
            var root_duration = (root_data.attr('data-duration') * 1).toFixed(3);
            var root_delay = (root_data.attr('data-delay') * 1).toFixed(3);

            // add to imports if it doesn't yet exist
            if (!import_list.hasOwnProperty(object_class_ns)) {
                import_list[object_class_ns] = true;
                imports += "    import " + object_class_ns + ";\n";
            }

            vars += "        public var " + object_name + ":" + object_class + ";\n";

            // add defaults to the properties of this object from the __root view
            exit_setup += "            " + object_name + " = CCSprite.createWithSpriteFrame(cache.spriteFrameByName(\"" + texture_name + "\"));\n";
            exit_setup += "            " + object_name + ".x = " + root_pos_x + ";\n";
            exit_setup += "            " + object_name + ".y = " + root_pos_y + ";\n";
            exit_setup += "            " + object_name + ".scale = " + root_scale + ";\n";
            exit_setup += "            " + object_name + ".opacity = " + Math.round(root_opacity * 255) + ";\n";
            exit_setup += "            parent.addChild(" + object_name + ");\n\n";

            // export tweens for the view
            if (pos_x !== root_pos_x || pos_y !== root_pos_y || scale !== root_scale || opacity !== root_opacity)
                tweens += "            Tween.to(" + object_name + ", " + duration + ", {" + (pos_x !== root_pos_x ? "'x': " + pos_x + ", " : "") + (pos_y !== root_pos_y ? "'y': " + pos_y + ", " : "") + (scale !== root_scale ? "'scale': " + scale + ", " : "") + (opacity !== root_opacity ? "'opacity': " + Math.round(opacity * 255) + ", " : "") + "'delay': " + delay + ", 'ease': " + easing + "});\n";

            // export tweens for exit
            if (pos_x !== root_pos_x || pos_y !== root_pos_y || scale !== root_scale || opacity !== root_opacity)
                exit_tweens += "            Tween.to(" + object_name + ", " + root_duration + ", {" + (pos_x !== root_pos_x ? "'x': " + root_pos_x + ", " : "") + (pos_y !== root_pos_y ? "'y': " + root_pos_y + ", " : "") + (scale !== root_scale ? "'scale': " + root_scale + ", " : "") + (opacity !== root_opacity ? "'opacity': " + Math.round(root_opacity * 255) + ", " : "") + "'delay': " + root_delay + ", 'ease': " + root_easing + "});\n"; //" + (entity.attr('id') == root_longest_animating ? ".onComplete += onExitComplete" : "") + "
        });

        export_ls = export_ls
            .replace(/\%project_name\%/g, project_name)
            .replace(/\%capital_viewname\%/g, capital_viewname + "")
            .replace(/\%lower_viewname\%/g, lower_viewname + "")
            .replace(/\%imports\%/g, imports + "")
            .replace(/\%vars\%/g, vars + "")
            .replace(/\%exit_setup\%/g, exit_setup + "")
            .replace(/\%tweens\%/g, tweens + "")
            .replace(/\%exit_tweens\%/g, exit_tweens + "");
        $$.addDownloadLink(capital_viewname + ".ls", base64_encode(export_ls));
    });

    log("Export successful. Click to download your files.");

    $("#downloads").fadeIn();

    return true;
};

LMLScene.prototype.addDownloadLink = function (filename, base64content) {
    $("#links").append('<div><a href="data:application/octet-stream;charset=utf-8;base64,' + base64content + '" download="' + filename + '">' + filename + '</div>');
};
