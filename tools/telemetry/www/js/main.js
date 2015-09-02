//var colors = ["#3A3232", "#D83018", "#F07848", "#FDFCCE", "#C0D8D8"];
var colors = ["#611824", "#C12F2A", "#FF6540", "#FEDE7B", "#F7FFEE"];
var invertGraph = true;

var timeInitRange = 20e6;
var tickInitNum = 60;

var tickLimit = tickInitNum;
var tickShowValues = false;

var tickOffset = 0;
var chartOffset = 0.0;
var tickNum = tickInitNum;
var tickNumF = tickInitNum;

var innerChartWidth = 0;
var expectedBarWidth = 0;
var chartWidthExtension = 0;

var Signal = signals.Signal;

var LT = {
    startStream: function() {
        Telemetry.stream.start();
    },
    stopStream: function() {
        Telemetry.stream.stop();
    }
}

function initTelemetry() {
    var elem;
    elem = $("#tickLimit");
    elem.val(tickLimit);
    elem.blur(updateTickLimit);
    elem.keyup(function(e) {
        // On enter
        if (e.keyCode == 13) { updateTickLimit(); }
    })
    
    elem = $("#toggleValues");
    elem.prop("checked", tickShowValues);
    elem.change(function() {
        tickShowValues = $("#toggleValues").prop("checked");
        Telemetry.tickValues.updateCommon(Telemetry.tickChart);
        Telemetry.tickBars.updateCommon(Telemetry.tickChart);
        Telemetry.tickChart.resize();
    })
    
    Telemetry.stream = new TStream();
    Telemetry.tickChart = new ChartCommon();
    Telemetry.processor = new TelemetryProcessor(Telemetry.tickChart);
    Telemetry.tickValues = new TickValues(Telemetry.tickChart);
    Telemetry.tickBars = new TickBars(Telemetry.tickChart);
    
    Telemetry.tickChart.tickViewChanged.add(Telemetry.processor.updateTickView);
    Telemetry.tickChart.tickViewChanged.add(Telemetry.tickBars.updateTickView);
    Telemetry.tickChart.tickViewChanged.add(Telemetry.tickValues.updateTickView);
    
    Telemetry.stream.messageCallback = Telemetry.processor.handleMessage;
    Telemetry.stream.showStatus("Ready");
    
    Telemetry.stream.start();
}

function updateTickLimit() {
    var limit = Number($("#tickLimit").val());
    if (!isNaN(limit)) tickLimit = limit;
}

function destroyTelemetry() {
    if (Telemetry.stream) Telemetry.stream.close();
}

var Telemetry = {
    ticks: [],
    valueDomains: null,
    filteredTicks: null,
    stream: null,
    processor: null,
    tickChart: null,
    tickValues: null,
    tickBars: null,
    
    statTicks: $(".statistic.ticks .value"),
    //statPingTime: $(".ui.statistic.pingTime .value"),
    updateStats: function() {
        Telemetry.statTicks.text(Telemetry.ticks.length);
        //Telemetry.statPingTime.text(Telemetry.stream.pingTime+"ms");
    },
    
    getTimeFromNano: function(nano) {
        if (nano < 1e3) return nano.toFixed(2)+"ns";
        if (nano < 1e6) return (nano * 1e-3).toFixed(2)+"\u00B5s";
        return (nano * 1e-6).toFixed(2)+"ms";
    },
    
    timeUnitLabels: {
        milliseconds: Mustache.render(d3.select("#tmplTimeUnit").html(), { name: "ms", classes: "teal" }),
        microseconds: Mustache.render(d3.select("#tmplTimeUnit").html(), { name: "\u00B5s", classes: "yellow" }),
        nanoseconds: Mustache.render(d3.select("#tmplTimeUnit").html(), { name: "ns", classes: "orange" }),
    },
    
    getTimeLabelFromNano: function(nano) {
        if (nano < 1e3) return nano.toFixed(2)+Telemetry.timeUnitLabels.nanoseconds;
        if (nano < 1e6) return (nano * 1e-3).toFixed(2)+Telemetry.timeUnitLabels.microseconds;
        return (nano * 1e-6).toFixed(2)+Telemetry.timeUnitLabels.milliseconds;
    },
    
};

function ChartCommon() {
    
    this.tickViewChanged = new Signal();
    this.resized = new Signal();
    
    this.margin = {
        top: 40,
        right: 0,
        rightWithValues: 340,
        rightWithoutValues: 300,
        bottom: 80,
        left: 130
    };
    this.width = 0;
    this.height = 0;
    
    this.topChartRatio = 0.3;
    
    this.timePos = 0;
    this.timeRange = timeInitRange;

    this.padding = 10;
    this.collapseSpacingWidth = 10;
    this.collapsedSpacing = 0;
    this.separatedSpacing = 0.1;
    
    this.x = d3.scale.ordinal()
    
    this.vx = d3.scale.linear()
        .domain([0, tickInitNum])
    
    this.y = d3.scale.linear()
        
    this.minTime = Infinity;
    this.maxTime = -Infinity;
    
    this.xZoom = d3.behavior.zoom()
    this.xDirty = false;
    
    var ticks;
    
    if (invertGraph) this.y.domain([this.timePos + this.timeRange, this.timePos]); else this.y.domain([this.timePos, this.timePos + this.timeRange]);
    
    this.init = function() {
        ticks = Telemetry.ticks;
        this.xZoom.on("zoom", this.xZoomed.bind(this))
        this.resize();
        this.xZoom.x(this.vx)
    }
    
    this.resize = function() {
        this.margin.right = tickShowValues ? this.margin.rightWithValues : this.margin.rightWithoutValues;
        
        this.width = $("#tickCharts").width() - this.margin.left - this.margin.right;
        this.height = $("#tickCharts").height() - this.margin.top - this.margin.bottom;
        
        //if (this.x.range().length == 0) {
            //this.x.rangeBands([this.padding, this.width-this.padding*2], this.spacing);
        //}
        this.vx.range([0, this.width])
        
        this.xDirty = true;
            
        this.resized.dispatch();
        this.updateTickView();
    }
    
    this.xConstrainScale = function() {
        var minScale = ticks.length == 0 ? Number.NEGATIVE_INFINITY : tickInitNum / ticks.length;
        var maxScale = Number.POSITIVE_INFINITY;
        this.xZoom.scaleExtent([minScale, maxScale]);
    }
    
    this.xUpdateSize = function() {
        var tickDomain = this.vx.domain();
        
        innerChartWidth = this.width - 2 * this.padding;
        
        tickNumF = tickDomain[1] - tickDomain[0];
        tickNum = Math.ceil(tickNumF - 1e-6);
        
        this.spacing = ticks.length > 0 && innerChartWidth/tickNumF < this.collapseSpacingWidth ? this.collapsedSpacing : this.separatedSpacing;
        
        expectedBarWidth = innerChartWidth/(tickNumF - this.spacing + 2 * this.spacing);
        
        chartWidthExtension = expectedBarWidth * (tickNum - tickNumF);
        
        //console.log(tickDomain)
    }
    
    this.xUpdatePosition = function() {
        var tickDomain = this.vx.domain();
        
        tickOffset = Math.floor(tickDomain[0]);
        chartOffset = (tickDomain[0] - tickOffset) * expectedBarWidth;
        
        //console.log(tickDomain, tickOffset, chartOffset)
    }
    
    
    this.xConstrainPosition = function() {
        this.xUpdateSize();
        
        var trans = this.xZoom.translate();
        var xMax = 0;
        var xMin = -this.width/(tickNumF)*(ticks.length - tickNumF);
        
        var tx = trans[0];
        var ty = trans[1];
        
        //console.log(tx, xMin)
        
        var touchingBorder = false;
        if (tx > xMax) {
            tx = xMax;
            touchingBorder = true;
        }
        if (tx < xMin) {
            tx = xMin - 1e-6;
            touchingBorder = true;
        }
        
        this.xZoom.translate([tx, ty]);
        
        this.xUpdatePosition();
    }
    
    this.xUpdate = function() {
        this.xDirty = false;
        this.xConstrainPosition();
        this.xConstrainScale();
        
        var tickPad = chartOffset-1e-3 > chartWidthExtension ? 1 : 0;
        //console.log(chartOffset, chartWidthExtension)
        tickNum += tickPad;
        
        this.x.rangeBands([-chartOffset + this.padding, -chartOffset + innerChartWidth + expectedBarWidth * (tickNum - tickNumF)], this.spacing);
    }
    
    this.xZoomed = function() {
        this.xDirty = true;
        this.updateTickView();
    }
    
    this.chartTransition = function(transition) {
        transition
            .duration(100)
            .ease(d3.ease("cubic-out"))
    }
    
    this.textLine = function(sel, className) {
        return sel.append("tspan")
            .attr("class", className)
            .attr("x", "0")
            .attr("dy", "1.5em")
    }
    
    this.getBoxFitAngle = function(boxWidth, boxHeight, textLength) {
        if (textLength < boxWidth) return 0;
        var angle = Math.acos(Math.min(boxWidth, boxHeight)/textLength)*180/Math.PI;
        if (isNaN(angle)) angle = 90;
        return angle;
    }
    
    this.updateDynamicText = function(selection, className, shouldExist, initialTransform) {
        var text = selection.select("."+className);
        var exists = text.size() > 0;
        if (!exists && shouldExist) {
            text = selection.append("text")
                .attr("class", className)
                .attr("transform", initialTransform)
        } else if (exists && !shouldExist) {
            text.remove();
        }
        return text;
    }
    
    this.filterTicks = function(axis, scale, tickSpace, tickCount) {
        
        var domain = scale.domain();
        var tickNum;
        if (!tickSpace && !tickCount) {
            tickSpace = 40;
        }
        if (tickSpace) {
            var extent = scale.rangeExtent();
            tickNum = (extent[1] - extent[0]) / tickSpace;
        } else {
            tickNum = tickCount;
        }
        
        var mod = Math.floor(domain.length/tickNum)
        var filteredDomain = domain.filter(function(d, i) {
            if (i == 0 || i == domain.length-1) return true;
            return !((domain.length - i) % mod);
        });
        axis.tickValues(filteredDomain);
        return filteredDomain;
    }
    
    this.updateTickView = function() {
        this.minTime = invertGraph ? this.y.domain()[1] : this.y.domain()[0];
        this.maxTime = invertGraph ? this.y.domain()[0] : this.y.domain()[1];
        
        if (this.xDirty) this.xUpdate();
        
        this.tickViewChanged.dispatch();
    }
    
    this.updateDynamicAxis = function(svgAxis, axis) {
        
        this.filterTicks(axis, this.x);
        
        var transform;
        switch (axis.orient()) {
            case "bottom": transform = this.getLabelTiltTransform(axis, this.margin.bottom, 9, 0, 0, 15); break;
            case "top":    transform = this.getLabelTiltTransform(axis, this.margin.bottom, 9, 0, 0, -15); break;
            default: throw new Error("Axis orientation unsupported: "+axis.orient());
        }
        
        axis(svgAxis)
        //axis(svgAxis.transition().call(this.chartTransition))
        svgAxis.selectAll("text")
            .style("text-anchor", "middle")
            .attr("y", 0)
            .attr("transform", transform)
        svgAxis.selectAll("text.label")
            .attr("dy", 30)
    }
    
    this.getLabelTiltTransform = function(axisX, height, charWidth, padding, ox, oy) {
        var domain = this.x.domain();
        var band = this.x.rangeBand(); 
        
        var crowdedRatio = domain.length / axisX.tickValues().length;
        var longestLabel = d3.max(domain);
        var estimatedLength = padding + charWidth*Math.LOG10E*Math.log(longestLabel);
        
        var angle = this.getBoxFitAngle(band*crowdedRatio, height, estimatedLength);
        var rad = angle*Math.PI/180;
        ox += oy*Math.sin(rad*2);
        oy += oy*Math.sin(rad);
        
        var labelTransform = "translate("+ox+" "+oy+") rotate("+angle+")";
        
        return labelTransform;
    }
    
    this.trimName = function(name, width) {
        var split = name.split(".");
        if (name.length <= width || split.length <= 1 || split[split.length-1].length + 3 >= name.length) {
            return { name: name, partial: false };
        }
        name = split[split.length-1];
        var fromLeft = false;
        var left = 0;
        var right = split.length-2;
        var nameLeft = "";
        var nameRight = "";
        while (left < right && name.length + nameLeft.length + nameRight.length + split[fromLeft ? left : right].length < width) {
            if (fromLeft) {
                nameLeft += split[left] + ".";
                left++;
            } else {
                nameRight = split[right] + "." + nameRight;
                right--;
            }
            fromLeft = !fromLeft;
        }
        if (nameRight.length > 0) name = nameRight + name;
        name = "&hellip;" + name;
        if (nameLeft.length > 0) name = nameLeft.substr(0, nameLeft.length-1) + name;
        return { name: name, partial: nameLeft.length + nameRight.length > 0 };
    }
    
    this.init();
}

function TStream() {
    this.pingInterval = 2;
    this.pingStart = 0;
    this.pingTime = 0;
    
    this.socket = null;
    this.pinger = -1;
    this.messageCallback = null;
    
    this.updateButtons = function() {
        var start = $(".startStream");
        var stop = $(".stopStream");
        if (this.socket != null) {
            start.addClass("hidden")
            stop.removeClass("hidden")
            if (this.socket.readyState != 1) {
                stop.addClass("loading");
            } else {
                stop.removeClass("loading");
            }
        } else {
            start.removeClass("hidden")
            stop.addClass("hidden")
        }
    }
    
    this.stop = function() {
        if (!this.socket) return;
        this.socket.close();
        this.socket.onopen = null;
        this.socket.onclose = null;
        this.socket.onmessage = null;
        this.socket.onerror = null;
        this.socket = null;
        clearInterval(this.pinger);
        this.showStatus("Stopped");
    }
    
    this.start = function() {
        this.stop();
        
        var wsproto = (location.protocol === "https:") ? "wss:" : "ws:";
        this.socket = new WebSocket(wsproto + "//" + window.location.host + "/stream");
        
        this.showStatus("Started");
        
        this.socket.onopen = function streamOpen(e) {
            this.showStatus("Stream opened");
            this.pinger = setInterval(function streamPing() { this.ping(); }.bind(this), this.pingInterval * 1000);
        }.bind(this);
        
        this.socket.onclose = function streamClose(e) {
            this.stop();
            this.showStatus("Stream closed ("+(e.wasClean ? "cleanly" : "uncleanly")+")");
        }.bind(this);
        
        this.socket.onmessage = function streamMessage(e) {
            if (!this.messageCallback) return;
            this.messageCallback(e.data);
        }.bind(this);
        
        this.socket.onerror = function streamError(e) {
            this.showStatus("Stream error");
            this.socket.close();
        }.bind(this);
    }
    
    this.showStatus = function(status) {
        console.log(status);
        this.updateButtons();
        $("#streamStatus").text(status);
    }
    
    this.ping = function() {
        if (!this.socket || this.socket.readyState != 1) return;
        this.showStatus("Ping time: "+this.pingTime+"ms (sending...)");
        d3.select(".statistic.pingTime .label").text("Pinging");
        this.pingStart = +new Date();
        this.socket.send("ping");
    }
    
    this.pong = function() {
        var now = +new Date();
        this.pingTime = now - this.pingStart;
        var sel = d3.select(".statistic.pingTime");
        sel.select(".value").text(this.pingTime + "ms")
        sel.select(".label").text("Ping time")
        this.showStatus("Ping time: "+this.pingTime+"ms");
    }
    
}




function TelemetryProcessor(initCommon) {
    
    this.tickAdded = new Signal();
    
    this.unprocessed = [];
    this.processor = -1;
    
    this.timerStack = [];
    this.totalDelta = 0;
    
    this.viewDirty = false;
    this.viewUpdateTime = 0;
    this.stepProcessed = 0;
    
    this.viewSkip = 0;
    
    this.totalDeltaHistory = [];
    this.unprocessedHistory = [];
    this.displayLoadHistory = [];
    
    this.viewSkipThreshold = 0;
    
    this.debug = "";
    
    this.init = function() {
        if (initCommon) this.updateCommon(initCommon);
        step.bind(this)(0);
        resize();
    }
    
    var chart;
    var x, y, padding, width;
    this.updateCommon = function(common) {
        chart = common;
        chart.resized.add(resize.bind(this))
    }
    function resize() {
        var common = chart;
        x = common.x;
        y = common.y;
        padding = common.padding;
        width = common.width;
    }
    
    var selProcessTime = d3.select(".statistic.processTime .value")
    var selUnprocessed = d3.select(".statistic.unprocessed .value")
    var selDisplayLoad = d3.select(".statistic.displayLoad .value")
    
    function pushTrimmed(array, length, value) {
        array.push(value)
        array.splice(0, array.length-length);
    }
    
    function step(timestamp) {
        //var viewSkipThreshold = (1-Math.exp(-this.unprocessed.length/20))*60; // Approach 60 skips at around 100 unprocessed
        //this.viewSkipThreshold = this.unprocessed.length/1.5;
        
        this.viewUpdateTime = 0;
        this.viewSkip++;
        if (this.viewSkip > this.viewSkipThreshold) {
            this.viewSkip = 0;
            this.flushView();
        }
        
        pushTrimmed(this.totalDeltaHistory, 60, this.totalDelta)
        var totalDeltaMean = d3.mean(this.totalDeltaHistory)
        selProcessTime.text("~" + totalDeltaMean.toFixed(2) + "ms")
        
        pushTrimmed(this.unprocessedHistory, 60, this.unprocessed.length)
        selUnprocessed.text("~" + d3.mean(this.unprocessedHistory).toFixed(2))
        
        var viewUpdatesPerSec = 60/(1+Math.floor(this.viewSkipThreshold));
        var viewUpdateLoad = viewUpdatesPerSec*this.viewUpdateTime/1000;
        
        pushTrimmed(this.displayLoadHistory, 60, viewUpdateLoad)
        var displayLoadMean = d3.mean(this.displayLoadHistory)
        
        this.viewSkipThreshold = Math.max(0, this.viewSkipThreshold + (viewUpdateLoad - 1) + this.unprocessed.length/10);
        
        selDisplayLoad.text("~" + (displayLoadMean*100).toFixed(0) + "%")
        
        
        
        /*
        this.debug = "Delta: " + this.totalDelta + "ms <br/>" +
                    this.viewUpdateTime + "ms <br/>" +
                    this.stepProcessed + "<br/>" +
                    viewSkipThreshold + "<br/>" +
                    this.debug;
        
        $("#debugOutput").html(this.debug);
        this.debug = "";
        */
        
        this.totalDelta = 0;
        this.stepProcessed = 0;
        
        window.requestAnimationFrame(step.bind(this));
    }
    
    this.flushView = function() {
        if (this.viewDirty) {
            this.viewDirty = false;
            this.tick();
            chart.tickViewChanged.dispatch();
            this.viewUpdateTime = this.tock();
        }
    }
    
    this.tick = function() {
        this.timerStack.push(+(new Date()));
    }
    
    this.tock = function() {
        var delta = (+new Date()) - this.timerStack.pop();
        this.totalDelta += delta;
        return delta;
    }
    
    this.handleMessage = function(msg) {
        this.tick();
        var m = JSON.parse(msg);
        switch (m.status) {
            case "success":
                this.addUnprocessed(m.data);
                break;
            case "pong":
                Telemetry.stream.pong();
                break;
            default:
                console.log("Result "+m.status+": "+m);
        }
        this.tock();
    }.bind(this)
    
    this.addUnprocessed = function(json) {
        this.unprocessed.push(json);
        //console.log("Pushed, " + this.unprocessed.length)
        this.processTick();
    }
    
    this.processTick = function() {
        var processed = 0;
        var budget = 14;
        while (this.stepProcessed == 0 || this.totalDelta < budget - this.viewUpdateTime) {
            if (this.unprocessed.length <= 0) {
                break;
            }
            this.tick();
            var json = this.unprocessed.shift();
            this.addTick(json);
            this.tock();
            processed++;
            this.stepProcessed++;
        }
        
        if (this.unprocessed.length <= 0) {
            if (this.processor != -1) clearInterval(this.processor);
            this.processor = -1;
        } else {
            if (this.processor == -1) {
                this.processor = setInterval(function() { this.processTick(); }.bind(this), 10);
            }
        }
        
        this.debug += "Processed: " + processed + "  Pending: " + this.unprocessed.length + "<br/>";
        
        //console.log("Processed: " + processed + "  Pending: " + this.unprocessed.length);
    }
    
    this.addTick = function(tick) {
        this.tick();
        this.viewDirty = true;
        var newTick = {
            id: tick.values["tickId"],
            values: tick.values,
            metrics: tick.ranges,
            visibleMetrics: null,
            maxLevel: 0,
            sectionsVisible: false
        };
        Telemetry.ticks.push(newTick);
        
        if (!isNaN(tickLimit) && Telemetry.ticks.length > tickLimit) Telemetry.ticks.splice(0, Telemetry.ticks.length - tickLimit);
        
        updateMaxLevel(newTick);
        sortMetrics(newTick);
        this.tickAdded.dispatch(newTick);
        Telemetry.updateStats();
        this.tock();
        
        //if (Telemetry.ticks.length >= tickInitNum) Telemetry.stream.stop();
    }
    
    function updateMaxLevel(tick) {
        tick.maxLevel = d3.max(tick.metrics, function(metric) { return metric.level; });
    }
    
    function sortMetrics(tick) {
        tick.metrics = tick.metrics.sort(function(a, b) {
            if (a.level < b.level) return -1;
            if (a.level > b.level) return 1;
            if (a.sibling < b.sibling) return -1;
            if (a.sibling > b.sibling) return 1;
            return 0;
        });
    }
    
    function cullMetrics(tick) {
        var lx = x(tick.id);
        var rx = lx + x.rangeBand();
        
        lx = Math.max(padding, lx);
        rx = Math.min(width, rx);
        
        var visibleWidth = rx-lx;
        
        tick.sectionsVisible = visibleWidth > 300;
        if (tick.sectionsVisible) {
            var minTime = chart.minTime;
            var maxTime = chart.maxTime;
            tick.visibleMetrics = tick.metrics.filter(function(metric, index, metrics) {
                if (metric.a > maxTime || metric.b < minTime) return false;
                if (y(metric.b) - y(metric.a) < 1) return false;
                return true;
            })
        } else {
            tick.visibleMetrics = tick.metrics.length > 0 ? [tick.metrics[0]] : [];
        }
        return tick;
    }
    
    this.updateTickView = updateTickView;
    function updateTickView() {
        var ticks = Telemetry.ticks;
        
        var sliceStart = Math.max(0, tickOffset)
        var sliceEnd = Math.min(ticks.length, tickOffset + tickNum)
        var slicedTicks = ticks.slice(sliceStart, sliceEnd)
        
        //console.log(tickOffset, tickNum, sliceStart, sliceEnd)
        
        x.domain(slicedTicks.map(function(tick) {
            return tick.id;
        }));
        
        Telemetry.filteredTicks = slicedTicks.map(cullMetrics);
        
    }
    
    this.init();
}
    
    
    
    
    
function TickValues(initCommon) {

    var map;
    var domains;
    var ticksDirty = false;
    
    this.init = function() {
        if (initCommon) this.updateCommon(initCommon);
        Telemetry.processor.tickAdded.add(this.onTickAdded);
        resize();
    }
    
    var chart;
    var width, height, margin, x, y;
    
    this.updateCommon = function(common) {
        chart = common;
        chart.resized.add(resize.bind(this))
    }
    
    function resize() {
        svgRoot.style("display", tickShowValues ? "block" : "none")
        
        width = chart.width;
        height = chart.height * chart.topChartRatio;
        
        margin = {
            left: chart.margin.left,
            right: chart.margin.right,
            top: 70,
            bottom: 0
        };
        x = chart.x;
        y = chart.y;
        
        svgRoot
            .attr("width", width + margin.left + margin.right)
            .attr("height", height + margin.top + margin.bottom)
        
        svg
            .attr("transform", "translate(" + margin.left + " " + margin.top + ")")
        
        svgAxisX
            .attr("transform", "translate(" + 0 + " " + 0 + ")")
    }
    
    var svgRoot = d3.select("#tickCharts").append("svg")
        .attr("class", "tickValues")
    
    var svg = svgRoot.append("g")
    
    var svgLines = svg.append("g")
    
    var svgAxisX = svg.append("g")
        .attr("class", "x axis unselectable")
        
    var axisX = d3.svg.axis()
        .orient("top")
    
    function updateDomains(ticks) {
        domains = d3.map();
        ticks.forEach(function(tick) {
            var tickValues = tick.values;
            for (var key in tickValues) {
                var domain = domains.get(key);
                if (domain == undefined) {
                    //domain = [Number.POSITIVE_INFINITY, Number.NEGATIVE_INFINITY];
                    domain = [0, Number.NEGATIVE_INFINITY];
                    domains.set(key, domain);
                }
                var value = tickValues[key];
                if (value < domain[0]) domain[0] = value;
                if (value > domain[1]) domain[1] = value;
            }
        })
    }
    
    function updateValueMap(ticks) {
        if (!domains) throw new Error("Unable to update value map with undefined domains")
        var valueMapLen = 0;
        map = d3.map();
        // Gather keys
        ticks.forEach(function(tick) {
            var tickValueMap = tick.values;
            for (var key in tickValueMap) {
                if (key == "tickId") continue; // Ignore IDs
                //if (key != "gc.memory") continue; // Debug - only show memory
                var entry = map.get(key);
                if (entry == undefined) {
                    entry = {
                        name: key,
                        values: [],
                        //valueMin: Number.POSITIVE_INFINITY,
                        //valueMax: Number.NEGATIVE_INFINITY,
                        domain: domains.get(key),
                        scale: d3.scale.linear()
                            .range([1, 0]),
                        axisY: d3.svg.axis()
                            .orient("right")
                            .ticks(2)
                    };
                    map.set(key, entry);
                }
                var value = tickValueMap[key];
                entry.values.push([tick.id, value]);
                /*
                if (value < entry.valueMin) entry.valueMin = value;
                if (value > entry.valueMax) entry.valueMax = value;
                */
            }
            valueMapLen++;
            map.forEach(function(key, entry) {
                if (entry.values.length < valueMapLen) entry.values.push([tick.id, NaN]);
            })
        })
        
        map.forEach(function(key, entry) {
            
            // Discretize to powers of 2
            var delta = entry.domain[1] - entry.domain[0];
            var sign = delta < 0 ? -1 : 1;
            entry.domain[1] = entry.domain[0] + Math.pow(2, Math.ceil(Math.LOG2E*Math.log(delta*sign)))*sign;
            
            entry.scale.domain(entry.domain)
        })
    }
    
    this.onTickAdded = function(tick) {
        this.updateTicks();
    }.bind(this)
    
    this.updateTicks = function() {
        ticksDirty = true;
        if (!tickShowValues) return;
        updateDomains(Telemetry.ticks);
        ticksDirty = false;
    }
    
    this.updateTickView = function() {
        if (!tickShowValues) return;
        if (!domains && ticksDirty) this.updateTicks();
        if (!domains) return;
        
        axisX.scale(x);
        chart.updateDynamicAxis(svgAxisX, axisX);
        
        updateValueMap(Telemetry.filteredTicks)
        
        var values = map.values();
        
        var lines = svgLines.selectAll(".line").data(values)
        
        // Tick bars, new only, group inside of a bar
        var lineGroup = lines.enter().append("g")
            .attr("class", "line")
        
        lines.exit().remove()
        
        var halfWidth = x.rangeBand() * 0.5;
        
        var spacing = 0;
        
        var lanes = d3.scale.ordinal()
            .domain(d3.range(values.length))
            .rangeBands([height, 0], 0.15)
        
        var laneBand = lanes.rangeBand();
        var laneHeight = laneBand;
        
        /*
        var lineSplit = d3.scale.linear()
            .domain([0, 1])
            .range([0, height/values.length])
        
        var splitHeight = lineSplit(1) + spacing;
        */
        
        var line = d3.svg.area()
            .x(function(d) {
                return x(d[0]) + halfWidth
            })
            .y0(laneBand)
        
        lineGroup.append("g")
            .attr("class", "y axis unselectable")
        
        lineGroup.append("path")
            .attr("class", "valuePath")
        
        lineGroup.append("text")
            .attr("class", "valueName")
            .style("text-anchor", "start")
            
        lineGroup.append("text")
            .attr("class", "valueCurrent")
            .style("text-anchor", "end")
            
        //lineGroup.append("line")
        //    .attr("class", "valueBoundTop")
        lineGroup.append("line")
            .attr("class", "valueBoundBottom")
        
        var svgLine = svgLines.selectAll(".line")
            .attr("transform", function(entry, index) {
                return "translate(0 "+ lanes(index) + ")"
            })
        
        svgLine.select(".y.axis").each(function(entry, index) {
            var svgAxisY = d3.select(this).transition().call(chart.chartTransition)
                .attr("transform", "translate("+width+", 0)")
                
            entry.scale.range([laneBand, 0])
            entry.axisY
                .scale(entry.scale)
                //.tickValues(entry.scale.domain.filter)
            entry.axisY(svgAxisY)
            entry.scale.range([1, 0])
        })
        
        svgLine.select(".valueBoundBottom").transition().call(chart.chartTransition)
            .attr("x1", 0)
            .attr("y1", laneBand)
            .attr("x2", width)
            .attr("y2", laneBand)
        
        svgLine.select(".valueName")
            .attr("x", 6)
            .attr("y", laneBand-8)
            .text(function(entry, index) {
                return entry.name
            })
            
        svgLine.select(".valueCurrent").transition().call(chart.chartTransition)
            .attr("x", function(entry) {
                return x(entry.values[entry.values.length-1][0])
            })
            .attr("y", function(entry) {
                return 12+laneHeight*entry.scale(entry.values[entry.values.length-1][1])  
            })
            .text(function(entry) {
                return entry.values[entry.values.length-1][1].toFixed(3)
            })
            
        svgLine.select(".valuePath")
            .attr("d", function(entry, index) {
                return line.y1(function(d) {
                    var v = entry.scale(d[1])
                    return laneHeight * v;
                })(entry.values);
            })
        
    }.bind(this)
    
    
    this.init();
}

function TickBars(initCommon) {
    
    var ticks;
    
    this.init = function() {
        if (initCommon) this.updateCommon(initCommon);
        
        ticks = Telemetry.ticks;
            
        addTickLine(30);
        addTickLine(60);
        
        Telemetry.processor.tickAdded.add(this.onTickAdded);
        
        resize();
    }
    
    var chart;
    var margin, width, height, x, y, vx, padding, spacing;
    this.updateCommon = function(common) {
        chart = common;
        chart.resized.add(resize.bind(this))
        svgAxisXBack.call(chart.xZoom);
    }
    function resize() {
        margin = chart.margin;
        width = chart.width;
        height = tickShowValues ? (chart.height - $(".tickValues").height()) : chart.height;
        //height = chart.height * (tickShowValues ? 1 - chart.topChartRatio : 1);
        x = chart.x;
        y = chart.y;
        y.range([height, 0])
        vx = chart.vx;
        padding = chart.padding;
        spacing = chart.spacing;
        
        svgRoot
            .attr("width", width + margin.left + margin.right)
            .attr("height", height + margin.top + margin.bottom)
        
        svgClip
            .attr("width", width)
            .attr("height", height)
            
        svg
            .attr("transform", "translate(" + margin.left + "," + margin.top + ")")
            
        svgAxisX
            .attr("transform", "translate(0," + height + ")")
            
        barYZoom
            .y(y)
    }
    
    var axisX = d3.svg.axis()
        .orient("bottom");
    
    var axisY = d3.svg.axis()
        .orient("left")
    
    var svgRoot = d3.select("#tickCharts").append("svg")
        .attr("class", "tickBars")
    
    var svgClip = svgRoot.append("defs").append("clipPath")
        .attr("id", "clipContents")
        .append("rect")
    
    var svg = svgRoot
        .append("g")
    
    var svgBars = svg.append("g")
        .attr("class", "bars")
        .attr("clip-path", "url(#clipContents)")
    
    var svgBarsBack = svgBars.append("rect")
        .attr("class", "backRect grabbable")
        
    var svgAxisX = svg.append("g")
        .attr("class", "x axis unselectable")
    
    var svgAxisY = svg.append("g")
        .attr("class", "y axis")
    
    var svgAxisXBack = svgAxisX.append("rect")
        .attr("class", "backRect grabbable")
    
    svgAxisX.append("text")
        .attr("class", "label")
        .text("Tick #");
        
    svgAxisY.append("text")
        .attr("transform", "rotate(-90)")
        .attr("x", 0)
        .attr("y", 2)
        .attr("dy", "1em")
        .style("text-anchor", "end")
        .text("Tick in nanoseconds");
    
    var tickLines = {};
    function addTickLine(fps) {
        var svgLine = svg.append("g")
            .attr("class", "fps fps"+fps)
        svgLine.append("line")
            .attr("x1", 0)
            .attr("y1", 0)
            .attr("y2", 0)
            .attr("stroke-dasharray", "5,5")
            .attr("clip-path", "url(#clipContents)")
        svgLine.append("text")
            .attr("y", -5)
            .style("text-anchor", "end")
            .text(
                (1e9/fps).toFixed(0)+"ns | "+
                //(1e6/fps).toFixed(0)+"\u00B5s | "+
                (1e3/fps).toFixed(2)+"ms | "+
                (1/fps).toFixed(2)+"s | "+
                fps+"fps"
            );
        tickLines[fps] = { fps: fps, svg: svgLine, time: 0 };
    }
        
    var barYZoom = d3.behavior.zoom()
        .on("zoom", barZoomedY)
    svgBars.call(barYZoom);
    
    /*
    function barZoomXAlignBars() {
        var trans = barXZoom.translate();
        console.log("align", trans, chartOffset);
        trans[0] += chartOffset;
        barXZoom.translate(trans);
        
        barZoomXUpdateSize();
        barZoomXUpdatePosition();
        
        console.log("aligned", barXZoom.translate(), chartOffset);
    }
    */
    
    function barZoomedY() {
        chart.updateTickView();
    }
    
    this.onTickAdded = function(tick) {
        updateTicks();
    }.bind(this)
    
    function updateTicks() {
    }
    
    this.updateTickView = updateTickView;
    function updateTickView() {
        
        //if (ticks.length >= tickInitNum) Telemetry.stream.socket.close();
        
        axisX.scale(x)
        chart.updateDynamicAxis(svgAxisX, axisX);
        
        axisY.scale(y)
        
        //console.log(cachedNum, totalNum, ((+new Date()) - time) + "ms");
        svgAxisY.transition().call(chart.chartTransition).call(axisY);
        
        svgAxisXBack
            .attr("width", width)
            .attr("height", margin.bottom)
            
        svgBarsBack
            .attr("width", innerChartWidth)
            .attr("height", height)
        
        updateTickLines();
        
        var durationRange = [0, tickLines[60].time];
        var durationPoints = d3.scale.ordinal().domain(d3.range(colors.length)).rangePoints(durationRange).range();
        var colorFromDuration = d3.scale.linear().domain(durationPoints).range(colors);
        
        var bars = svgBars.selectAll(".bar")
            .data(Telemetry.filteredTicks, function(tick) {
                return ""+tick.id;
            })
        
        // Tick bars, new only, group inside of a bar
        bars.enter().append("g")
            .attr("class", "bar grabbable")
            .attr("transform", function(tick, index) { return "translate(" +x(tick.id)+", 0)"; })
            //.style("opacity", function(tick, index) { return 1; })
        
        //bars.exit().remove()
        
        //bars.exit()
        //    .transition()
        
        // Delay removal of parent for 250.
        bars.exit()
            .transition().call(chart.chartTransition)
            /*
            .attr("transform", function(tick, index) {
                var t = d3.transform(d3.select(this).attr("transform"))
                var tx = t.translate[0]
                
                var hw = width*0.5;
                
                return "translate(" +(hw+(tx-hw)*1.20)+", 0)";
            })
            */
            .style("opacity", 0)
            .duration(100)
            .remove()
    
        // Tick bars, all
        bars
            .transition().call(chart.chartTransition)
            .attr("transform", function(tick, index) { return "translate(" +x(tick.id)+", 0)"; })
            .style("opacity", 1)
        
        // Tick bar sections, new
        var barSecAll = bars.selectAll(".bs")
            .data(function(tick) {
                return tick.visibleMetrics;
            }, function(tick) {
                return ""+tick.id;
            })
        
        // Tick bar sections, new only
        var barSecNew = barSecAll.enter()
        
        var barSecNewGroup = barSecNew.append("g")
            .attr("class", function(metric) { return "bs bs-"+metric.name; })
            .on("mouseover", function(metric) {
                if (metric.parent == -1) return;
                var template = d3.select("#tmplTooltip").html()
                var rendered = Mustache.render(template, {
                    duration: Telemetry.getTimeLabelFromNano(metric.b - metric.a),
                    enter:    Telemetry.getTimeLabelFromNano(metric.a),
                    exit:     Telemetry.getTimeLabelFromNano(metric.b),
                    name:     metric.name,
                    children: metric.children,
                    childrenPlural: metric.children == 1 ? "" : "ren",
                })
                
                d3.select("#tooltip")
                    .html(rendered)
                    .style("display", "block")
                    .transition()
                    .style("opacity", 1)
            })
            .on("mousemove", function(metric) {
                if (metric.parent == -1) return;
                var tooltip = d3.select("#tooltip")
                var m = d3.mouse(tooltip.node().parentNode)
                tooltip
                    .style("left", m[0] + "px")
                    .style("top",  m[1] + 10 + "px")
            })
            .on("mouseout", function(metric) {
                if (metric.parent == -1) return;
                d3.select("#tooltip")
                    .transition()
                    .style("opacity", 0)
                    .each("end", function() { this.style.display = "none" })
            })
        
        var barSecRemoved = barSecAll.exit()
        barSecRemoved.remove()
        
        barSecNewGroup.append("rect")
        
        bars.each(function updateBar(tick) {
            
            var metrics = tick.metrics;
            var maxLevel = tick.maxLevel;
            
            var fillLevels = false;
            var secX = d3.scale.linear().range([0, x.rangeBand()]).domain([0, maxLevel + (fillLevels ? 0 : 1)]);
            
            var barMaxY = Number.NEGATIVE_INFINITY;
            var barTotalDuration = 0;
            
            var bar = d3.select(this);
            var barInfo = bar.select(".barInfo")
            var barInfoExists = barInfo.size() > 0;
            var barInfoShouldExist = x.rangeBand() > 50;
            
            var barIsThin = x.rangeBand() < 20;
            bar.style("stroke", barIsThin ? "none" : null);
        
            if (!barInfoExists && barInfoShouldExist) {
                barInfo = bar.append("text")
                    .attr("class", "barInfo")
                    
                barInfo.call(chart.textLine, "nanoTime")
                barInfo.call(chart.textLine, "msTime")
            }
            if (barInfoExists && !barInfoShouldExist) barInfo.remove();
            
            bar.selectAll(".bs").each(function updateBarSection(metric, index) {
                
                var parent = metric.parent == -1 ? null : metrics[metric.parent]
                if (parent && metric.sibling == 0) {
                    parent.childNano = 0;
                }
                
                var ay = y(metric.a);
                var by = y(metric.b);
                var dy = by - ay;
                if (!invertGraph) dy = -dy;
                
                if (metric.level == 0) barTotalDuration += metric.b - metric.a;
                
                var sx = secX(metric.level);
                var sy = invertGraph ? ay : by;
                var sw = fillLevels ?
                        secX(maxLevel - metric.level) :
                        metric.parent == -1 ? x.rangeBand() : secX(1);
                var sh = dy;
                
                if (sy+sh > barMaxY) barMaxY = sy+sh;
                
                var barSec = d3.select(this);
                
                barSec.select("rect")
                    .style("fill", function updateBarSectionColor(metric, i) {
                        var color = colorFromDuration(metric.b - metric.a);
                        if (barIsThin) color = d3.lab(color).darker(0.15);
                        return color;
                    })
                    .transition().call(chart.chartTransition)
                    .attr("x", sx)
                    .attr("width", sw)
                    .attr("y", sy)
                    .attr("height", Math.max(1, sh))
                
                
                var bstX = sx;
                var bstY = sy + sh*0.5;
                
                var textFill;
                
                var bsttX = sx + sw*0.5;
                var bsttY = sy + sh - 5;
                var barSecText = barSec.select(".secName");
                var barSecTextTime = chart.updateDynamicText(
                    barSec,
                    "secTime",
                    tick.sectionsVisible && sh > 50,
                    "translate("+bsttX+" "+(bsttY+20)+")"
                );
                
                
                var barSecTextExists = barSecText.size() > 0;
                var barSecTextShouldExist = tick.sectionsVisible && sh > 15;
                
                if (!barSecTextExists && barSecTextShouldExist) {
                    barSecText = barSec.append("text")
                        .attr("class", "secName")
                        .attr("transform", "translate(" + bstX + " " + bstY + ")")
                }
                
                if (barSecTextExists && !barSecTextShouldExist) {
                    barSecText.remove();
                }
                
                
                
                if (barSecTextTime.size() > 0 || barSecTextShouldExist) {
                    var rectLab = d3.lab(barSec.select("rect").style("fill"))
                    textFill = rectLab.l > 80 ? "darkgray" : rectLab.brighter(3);
                }
                
                if (barSecTextTime.size() > 0) {
                    barSecTextTime.text(function(metric) {
                        return Telemetry.getTimeFromNano(metric.b-metric.a);
                    });
                    barSecTextTime.transition().call(chart.chartTransition)
                        .attr("text-anchor", "middle")
                        .attr("transform", "translate(" + bsttX + " " + bsttY + ")")
                        .style("fill", textFill)
                }
                
                
                if (barSecTextShouldExist) {
                    
                    var textHorizontalSpace = sw-(bstX-sx)*2;
                    var sectionName = metric.name;
                    var charWidth = 6.85;
                    //var charWidth = 4.5;
                    //var charWidth = 5;
                    var sidePadding = 10;
                    var textEstimatedLen = charWidth * sectionName.length;
                    var partialTrim = false;
                    if (textEstimatedLen > textHorizontalSpace) {
                        var trim = chart.trimName(sectionName, (textHorizontalSpace-sidePadding)/charWidth);
                        sectionName = trim.name;
                        textEstimatedLen = charWidth * sectionName.length;
                        partialTrim = trim.partial;
                    }
                    
                    barSecText.html(sectionName);
                    
                    // Compute the max char width and print to console
                    /*
                    var barSecTextNode = barSecText.node();
                    var textLen = barSecTextNode ? barSecTextNode.getComputedTextLength() : 0;
                    if (!LT.debugMetrics) LT.debugMetrics = []; LT.debugMetrics.push(textLen/sectionName.length); console.log(d3.max(LT.debugMetrics))
                    //*/
                    
                    console.log()
                    
                    var textVert = !partialTrim && textEstimatedLen > textHorizontalSpace && textEstimatedLen < sh;
                    
                    var bstOOBSpaceCheck = 10;
                    var bstOOBSpacePosition = 10;
                    
                    if (textVert) bstOOBSpaceCheck += textEstimatedLen*0.5;
                    
                    var bstOOB =
                        bstY > y.range()[0] - bstOOBSpaceCheck ? 0 :
                        bstY < y.range()[1] + bstOOBSpaceCheck ? 1 : -1;
                    
                    if (bstOOB != -1) {
                        bstY = y.range()[bstOOB] + bstOOBSpacePosition * (bstOOB == 0 ? -1 : 1);
                        textVert = false;
                    }
                    
                    bstX += textVert ? -3+sw*0.5 : 5;
                    
                    var vertAngle = Math.acos(Math.min(sw, sh)/(textEstimatedLen+40))*180/Math.PI;
                    if (isNaN(vertAngle)) vertAngle = 90;
                    
                    barSecText
                        .attr("text-anchor", textVert ? "middle" : "start")
                        .style("fill", textFill)
                        .transition().call(chart.chartTransition)
                        .attr("transform", "translate(" + bstX + " " + bstY + ") rotate("+(textVert ? vertAngle : 0)+")")
                        .attr("height", sh)
                        .attr("dy", (textVert ? 0 : 3))
                        
                        
                }
                
                if (parent) parent.childNano += metric.a;
                
            });
            
            if (barInfoShouldExist && barMaxY != -Infinity) {
                var barInfoLen = 0;
                barInfoLen = Math.max(barInfoLen, barInfo.select(".nanoTime").text(barTotalDuration.toFixed(3) + " ns").node().getComputedTextLength())
                barInfoLen = Math.max(barInfoLen, barInfo.select(".msTime").text((barTotalDuration * 1e-6).toFixed(3) + " ms").node().getComputedTextLength())
                
                var barInfoHeight = barInfo.node().clientHeight;
                var barInfoAngle = chart.getBoxFitAngle(x.rangeBand(), 100, barInfoLen + 40);
                
                barInfo.transition().call(chart.chartTransition)
                    .attr("width", x.rangeBand())
                    .attr("height", barInfoHeight)
                    .attr("text-anchor", "start")
                    .attr("transform", "translate("+Math.sin(barInfoAngle*Math.PI/180)*barInfoHeight+" "+(barMaxY)+") rotate("+barInfoAngle+") ")
            }
            
        })
        
    }
    
    function updateTickLines() {
        for (var fps in tickLines) {
            var tickLine = tickLines[fps];
            tickLine.time = 1e9/tickLine.fps;
            var height = y(tickLine.time);
            tickLine.svg.attr("transform", "translate(0, " + height + ")");
            tickLine.svg.select("line")
                .attr("x2", width)
            tickLine.svg.select("text")
                .attr("x", width)
        
        }
    }
        
    this.init();
}

$(document).ready(function() { initTelemetry(); });
$(document).on("beforeunload", function() { destroyTelemetry(); });
$(window).on("resize", function() { Telemetry.tickChart.resize() })