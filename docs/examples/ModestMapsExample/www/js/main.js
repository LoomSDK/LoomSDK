/// <reference path="../../../../../typings/d3/d3.d.ts"/>
/// <reference path="../../../../../typings/jquery/jquery.d.ts"/>

//var svgValues = d3.select("body").append("svg")

var ticks = [];
var stream;
var pingTime = 20;
var pinger;
//var colors = ["#3A3232", "#D83018", "#F07848", "#FDFCCE", "#C0D8D8"];
var colors = ["#611824", "#C12F2A", "#FF6540", "#FEDE7B", "#F7FFEE"];
var invertGraph = true;

var timeInitRange = 20e6;
var tickInitNum = 5;

var timePos = 0;
var timeRange = timeInitRange;

var tickOffset = 0;
var chartOffset = 0.0;
var tickNum = tickInitNum;
var tickNumF = tickInitNum;

var minTime = 0;
var maxTime = 0;

var innerChartWidth = 0;
var expectedBarWidth = 0;
var chartWidthExtension = 0;
var barXZoomMaxed = false;

function streamStatus(status) {
    console.log(status);
    $("#streamStatus").text(status);
}

function streamPing() {
    if (!stream || stream.readyState != 1) return;
    streamStatus("Sent ping at "+Date.now());
    stream.send("ping");
}

$(document).ready(function () {
    
    var wsproto = (location.protocol === "https:") ? "wss:" : "ws:";
    stream = new WebSocket(wsproto + "//" + window.location.host + "/stream");
    stream.onopen = function (e) {
        streamStatus("Stream opened");
        pinger = setInterval(streamPing, pingTime*1000);
    }
    stream.onclose = function (e) {
        streamStatus("Stream closed "+(e.wasClean ? "cleanly" : "uncleanly")+" with code "+e.code+" and reason: "+e.reason);
        clearInterval(pinger);
    }
    stream.onmessage = function (e) {
        //streamStatus(e.data);
        handleMessage(e.data);
    }
    stream.onerror = function (e) {
        streamStatus("Stream error");
        stream.close();
    }
    
    /*
    $("#tickMetrics").jqGrid({
        colModel: [
            {
                label: 'Time in nanoseconds',
                name: 'tickNano',
                width: 150
            }
        ],

        viewrecords: true, // show the current page, data rang and total records on the toolbar
        width: 780,
        height: 200,
        rowNum: 15,
        datatype: 'local',
        pager: "#jqGridPager",
        caption: "Tick metrics"
    });
    */
    
    /*
    fetchGridData();
    setInterval(fetchGridData, 500);
    */

});

var margin = {top: 20, right: 20, bottom: 60, left: 100},
    width = 960 - margin.left - margin.right,
    height = 1100 - margin.top - margin.bottom;

var padding = 10;
var spacing = 0.1;
var x = d3.scale.ordinal()
    x.rangeRoundBands([padding, width-padding*2], spacing);

var vx = d3.scale.linear()
    .domain([0, tickInitNum])
    .range([0, width])
    
var y = d3.scale.linear()
    .range([height, 0])
    
if (invertGraph) y.domain([timePos + timeRange, timePos]); else y.domain([timePos, timePos + timeRange]);

var axisX = d3.svg.axis()
    .orient("bottom");

var axisY = d3.svg.axis()
    .orient("left")

var svgRoot = d3.select("body").append("svg")
    .attr("class", "tickBars")
    .attr("width", width + margin.left + margin.right)
    .attr("height", height + margin.top + margin.bottom)

var svgClip = svgRoot.append("defs").append("clipPath")
    .attr("id", "clipContents")
    .append("rect")
        .attr("x", 0)
        .attr("y", 0)
        .attr("width", width)
        .attr("height", height)

var svg = svgRoot
    .append("g")
        .attr("transform", "translate(" + margin.left + "," + margin.top + ")")

var svgBars = svg.append("g")
    .attr("class", "bars")
    .attr("clip-path", "url(#clipContents)")
    /*
    .append("rect")
        .attr("x", 0)
        .attr("y", 0)
        .attr("width", width)
        .attr("height", height)
    */

var svgBarsBack = svgBars.append("rect")
    .attr("class", "backRect grabbable")
    
var svgAxisX = svg.append("g")
    .attr("class", "x axis unselectable")
    .attr("transform", "translate(0," + height + ")")
  
var svgAxisY = svg.append("g")
    .attr("class", "y axis")

var svgAxisXBack = svgAxisX.append("rect")
    .attr("class", "backRect grabbable")
    .attr("x", 0)
    .attr("y", 0)
    .attr("width", 0)
    .attr("height", 0)

svgAxisX.append("text")
    .attr("x", 0)
    .attr("y", 10)
    .attr("dy", "0em")
    .style("text-anchor", "end")
    .text("Tick #");
    
svgAxisY.append("text")
    .attr("transform", "rotate(-90)")
    .attr("x", 0)
    .attr("y", 2)
    .attr("dy", "1em")
    .style("text-anchor", "end")
    .text("Tick in nanoseconds");

/*

    svgLine.append("rect")
        .attr("class", "tickLine")
        .attr("x", 0)
        .attr("width", width)
        .attr("height", 1)
        */

var tickLines = {};
function addTickLine(fps) {
    var svgLine = svg.append("g")
        .attr("class", "fps")
        .attr("class", "fps" + fps)
    svgLine.append("line")
        .attr("x1", 0)
        .attr("x2", width)
        .attr("y1", 0)
        .attr("y2", 0)
        .attr("stroke-dasharray", "5,5")
        .attr("clip-path", "url(#clipContents)")
    svgLine.append("text")
        .attr("x", width)
        .attr("y", -5)
        .style("text-anchor", "end")
        .text(
            (1e9/fps).toFixed(2)+"ns | "+
            (1e6/fps).toFixed(2)+"\u00B5s | "+
            (1e3/fps).toFixed(2)+"ms | "+
            (1/fps).toFixed(2)+"s | "+
            fps+"fps"
        );
    tickLines[fps] = { fps: fps, svg: svgLine, time: 0 };
}

addTickLine(30);
addTickLine(60);

function handleMessage(msg) {
    var m = JSON.parse(msg);
    
    if (m.status != "success") {
        console.log("Result "+m.status+": "+m);
        return;
    }
    
    addTick(m.data);
    
    /*
    gridArrayData.push(m.data.metrics);
    // set the new data
    $("#tickMetrics").jqGrid('setGridParam', { data: gridArrayData});
    // refresh the grid
    $("#tickMetrics").trigger('reloadGrid');
    */
}

function addTick(tick) {
    // TODO: array per column
    ticks.push({ id: tick.values[0].value, values: tick.values, metrics: tick.ranges, visibleMetrics: null, maxLevel: 0, sectionsVisible: false });
    updateMaxLevel(ticks[ticks.length-1]);
    sortMetrics(ticks[ticks.length-1]);
    
    updateMetricData();
}

var barXZoom = d3.behavior.zoom()
    //.scale(width)
    //.scale(tickInitNum)
    .x(vx)
    .on("zoom", barZoomedX)
    
var barYZoom = d3.behavior.zoom()
    //.y(d3.scale.linear().domain([margin.y, height]).range([0, timeInitRange]))
    .y(y)
    .on("zoom", barZoomedY)
    
d3.select("svg .x.axis .backRect").call(barXZoom);
d3.select("svg .bars").call(barYZoom);

function barZoomXConstrainScale() {
    var minScale = tickInitNum / ticks.length;
    var maxScale = Number.POSITIVE_INFINITY;
    barXZoom.scaleExtent([minScale, maxScale]);
    
    /*
    var zoomScale = barXZoom.scale();
    if (zoomScale < minScale) barXZoom.scale(minScale);
    
    barXZoomMaxed = false;
    if (zoomScale > maxScale) {
        barXZoom.scale(maxScale);
        barXZoomMaxed = true;
    }
    */
}

function barZoomXUpdateSize()
{
    var tickDomain = vx.domain();
    
    innerChartWidth = width - 2 * padding;
    
    tickNumF = tickDomain[1] - tickDomain[0];
    tickNum = Math.ceil(tickNumF - 1e-6);
    
    expectedBarWidth = innerChartWidth/(tickNumF - spacing + 2 * spacing);
    
    chartWidthExtension = expectedBarWidth * (tickNum - tickNumF);
}

function barZoomXUpdatePosition() {
    var tickDomain = vx.domain();
    
    tickOffset = Math.floor(tickDomain[0]);
    chartOffset = (tickDomain[0] - tickOffset) * expectedBarWidth;
}


function barZoomXConstrainPosition() {
    barZoomXUpdateSize();
    
    var trans = barXZoom.translate();
    var xMax = 0;
    //var xMin = -expectedBarWidth*(ticks.length - tickNumF);
    var xMin = -width/(tickNumF)*(ticks.length - tickNumF);
    
    var tx = trans[0];
    var ty = trans[1];
    
    //console.log(tx, widthExtension, expectedBarWidth, tickNum, width, xMin);
    
    //console.log(chartOffset, widthExtension);
    
    var touchingBorder = false;
    if (tx > xMax) {
        tx = xMax;
        touchingBorder = true;
    }
    if (tx < xMin) {
        tx = xMin - 1e-6;
        touchingBorder = true;
    }
    
    barXZoom.translate([tx, ty]);
    
    barZoomXUpdatePosition();
}

function barZoomXAlignBars() {
    var trans = barXZoom.translate();
    console.log("align", trans, chartOffset);
    trans[0] += chartOffset;
    barXZoom.translate(trans);
    
    barZoomXUpdateCount();
    barZoomXUpdatePosition();
    
    console.log("aligned", barXZoom.translate(), chartOffset);
}

function barZoomedX() {
    //tickOffset = d3.event.translate[1]/5;
    //tickNum = Math.max(1, tickInitNum * d3.event.scale);
    
    //padding = 0;
    //spacing = 0;
    
    //barZoomXUpdateCount();
    //barZoomXUpdatePosition();
    
    barZoomXConstrainPosition();
    
    //barZoomXAlignBars();
    
    //console.log(chartOffset);
    
    //var tickPad = chartOffset == 0 ? 0 : 1;
    var tickPad = chartOffset-1e-3 > chartWidthExtension ? 1 : 0;
    //console.log(chartOffset, chartWidthExtension);
    tickNum += tickPad;
    
    //tickNumF += tickPad;
    
    //var barWidth = x.rangeBand() * (1 + spacing);
    
    //var newScale = d3.event.scale;
    //var prevTickNum = tickNum;
    //var tickPad = 0//tickNum >= ticks.length ? 0 : 1;
    
    //var to = tx;
    
    //tickOffset = Math.floor(-to/barWidth);
    //var offset = to + tickOffset * barWidth;
    
    
    //var tickNumF = newScale/(width/tickInitNum);
    //var tickNumF = newScale;
    
    //tickOffset = Math.max(0, tickOffset);
    //tickOffset = Math.min(ticks.length - tickNum - 1, tickOffset);
    
    //offset = Math.min(0, offset);
    //offset = Math.max(barWidth, offset);
    
    //tickNum = Math.max(1, tickNum);
    
    //console.log(vx.range(), vx.domain(), tickNum, tickNum-tickNumF)
    
    //barWidth = width/tickNum;
    
    //tickNum = Math.max(0, tickInitNum * d3.event.scale) + tickPad;
    
    //var chartWidth = width - (tickNumF-tickNum)*barWidth - padding*2;
    
    //var chartWidth = width - padding*2;
    
    //console.log(width, newScale, tickNum*barWidth, (tickNumF-tickNum)*barWidth, tickNum, ticks.length)
    
    //console.log(zoomX, tickOffset, offset, spacing)
    
    //x.rangeRoundBands([padding + offset, chartWidth + tickPad*barWidth + offset], spacing);
    //x.rangeRoundBands([-offset, -offset + width], spacing);
    x.rangeBands([-chartOffset + padding, -chartOffset + innerChartWidth + expectedBarWidth * (tickNum - tickNumF)], spacing);
    updateMetricData();
}

function barZoomedY() {
    updateMetricData();
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
        tick.visibleMetrics = tick.metrics.filter(function(metric, index, metrics) {
            //metric.oob = metric.a > maxTime || metric.b < minTime
            if (metric.a > maxTime || metric.b < minTime) return false;
            if (y(metric.b) - y(metric.a) < 1) return false;
            return true;
        })
    } else {
        tick.visibleMetrics = tick.metrics.length > 0 ? [tick.metrics[0]] : [];
    }
    return tick;
}

function chartTransition(transition) {
    transition
        .duration(100)
        .ease(d3.ease("cubic-out"))
}

function textLine(sel, className) {
    return sel.append("tspan")
        .attr("class", className)
        .attr("x", "0")
        .attr("dy", "1.5em")
}

function getBoxFitAngle(boxWidth, boxHeight, textLength) {
    if (textLength < boxWidth) return 0;
    var angle = Math.acos(Math.min(boxWidth, boxHeight)/textLength)*180/Math.PI;
    if (isNaN(angle)) angle = 90;
    return angle;
}

function getTimeFromNano(nano) {
    if (nano < 1e3) return nano.toFixed(2)+"ns";
    if (nano < 1e6) return (nano * 1e-3).toFixed(2)+"\u00B5s";
    return (nano * 1e-6).toFixed(2)+"ms";
}

function updateDynamicText(selection, className, shouldExist, initialTransform) {
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

function updateMetricData() {
    
    barZoomXConstrainScale();
    
    ticks = ticks.slice(-60);
    
    if (ticks.length >= 1) stream.close();
    
    //barXZoom.scaleExtent([0, ticks.length])
    
    //x.domain(data.map(function(d) { return d.id; }));
    //x.domain(data.map(function(d) { return d[0].value; }));
    
    var sliceStart = Math.max(0, tickOffset)
    var sliceEnd = Math.min(ticks.length, tickOffset + tickNum)
    var slicedTicks = ticks.slice(sliceStart, sliceEnd)
    
    x.domain(slicedTicks.map(function(tick) {
        return tick.id;
    }));
    
    /*
    console.log(tickOffset, tickNum, ticks.map(function(tick) {
        return tick.id;
    }));
    //*/
    
    //y.domain([0, d3.max(data, function(d) { return d.tickNano; })]);
    
    axisX.scale(x);
    axisY.scale(y)
    svgAxisX.call(axisX).selectAll("text")
        .style("text-anchor", "middle")
        .attr("dx", "0em")
        .attr("dy", "0em")
        .attr("transform", function(data) {
            var angle = getBoxFitAngle(x.rangeBand(), margin.bottom, 15 + this.getComputedTextLength());
            var offset = 10*Math.sin(angle*Math.PI/180);
            var tx = offset;
            var ty = offset + 15;
            return "translate("+tx+" "+ty+") rotate("+angle+")";
        })
    ;
    svgAxisY.call(axisY);
    
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
    
    minTime = invertGraph ? y.domain()[1] : y.domain()[0];
    maxTime = invertGraph ? y.domain()[0] : y.domain()[1];
    
    //minTime *= 1.1;
    //maxTime *= 0.9;
    
    // Tick bars
    //var bars = svgBars.selectAll(".bar").data(data);
    //*
    
    /*
    var bars = svgBars.selectAll(".bar").data(ticks.map(function(tick) {
        //var metricsBefore = metrics.length;
        tick.metrics = tick.metrics.filter(function(metric, index, metrics) {
            //console.log(metric.a, metric.b, minTime, maxTime)
            metric.oob = metric.a > maxTime || metric.b < minTime
            if (metric.a > maxTime || metric.b < minTime) return false;
            if (y(metric.b) - y(metric.a) < 1) return false;
            return true;
        })
        //console.log(metricsBefore, metrics.length);
        return tick;
    }))
    */
    
    var prunedSlicedTicks = slicedTicks.map(cullMetrics);
    
    var bars = svgBars.selectAll(".bar").data(prunedSlicedTicks, function(tick) {
        return ""+tick.id;
    })
    
    //*/
    
    // Only new ones
    /*
    update.enter().append("rect")
        .attr("class", "bar")
    */
    
    // Tick bars, new only, group inside of a bar
    var barGroup = bars.enter().append("g")
        .attr("class", "bar grabbable")
    
    /*
    var barInfo = barGroup.append("text")
        .attr("class", "barInfo")
        
    barInfo.call(textLine, "nanoTime")
    barInfo.call(textLine, "msTime")
    */
    
    bars.exit().remove()
    
    // Tick bars, all
    bars
        .attr("transform", function(tick, index) { return "translate(" +x(tick.id)+", 0)"; })
    
    //bars.each(cullMetrics);
    
    // Tick bar sections, new
    var barSecAll = bars.selectAll(".bs")
        .data(function(tick) {
            return tick.visibleMetrics;
        }, function(tick) {
            return ""+tick.id;
        })
    
    //console.log(bars.data()[0].metrics.length, barSecAll)
    
    // Tick bar sections, new only
    var barSecNew = barSecAll.enter()
    var barSecNewGroup = barSecNew.append("g")
        .attr("class", function(metric) { return "bs bs-"+metric.name; })
    
    var barSecRemoved = barSecAll.exit()
    barSecRemoved.remove()
    
    //console.log("new", barSecNew.size(), "removed", barSecRemoved.size())
    
    barSecNewGroup.append("rect")
    
    /*
    barSecNew.selectAll("rect")
        .attr("y", function(metric, i) { return y(metric.value); })
        .attr("height", function(metric, i) { return height - y(metric.value); });
    */
    
    //*
    bars.each(function(tick) {
        
        var metrics = tick.metrics;
        var maxLevel = tick.maxLevel;
        
        var fillLevels = false;
        var secX = d3.scale.linear().range([0, x.rangeBand()]).domain([0, maxLevel + (fillLevels ? 0 : 1)]);
        
        var barSecY = 0;
        var graphTop = y(0);
        var barMaxY = Number.NEGATIVE_INFINITY;
        var barTotalDuration = 0;
        
        var bar = d3.select(this);
        var barInfo = bar.select(".barInfo")
        var barInfoExists = barInfo.size() > 0;
        var barInfoShouldExist = x.rangeBand() > 50;
        
        if (!barInfoExists && barInfoShouldExist) {
            barInfo = bar.append("text")
                .attr("class", "barInfo")
                
            barInfo.call(textLine, "nanoTime")
            barInfo.call(textLine, "msTime")
        }
        if (barInfoExists && !barInfoShouldExist) barInfo.remove();
        
        //var barTextOOB = [];
        
        bar.selectAll(".bs").each(function(metric, index) {
            
            var parent = metric.parent == -1 ? null : metrics[metric.parent]
            //console.log(bar, metric)
            //var secY = d3.scale.linear().domain([0, parent ? parent.value : 1]).range([0, parent ? parent.value : 100])
            
            //console.log(metric, secY(0), secY(1), y(secY(metric.sibling)))
            
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
            
            //barSec.attr("transform", "translate("+sx+", "+sy+")")
            
            barSec.select("rect")
                .style("fill", function(metric, i) {
                    return colorFromDuration(metric.b - metric.a);
                })
                .transition().call(chartTransition)
                .attr("x", sx)
                .attr("y", sy)
                .attr("width", sw)
                .attr("height", Math.max(1, sh))
                //.style("fill", metric.oob ? "#FF0000" : "#0000FF")
            
            
            var bstX = sx;
            var bstY = sy + sh*0.5;
            
            var textFill;
            
            var bsttX = sx + sw*0.5;
            var bsttY = sy + sh - 5;
            var barSecText = barSec.select(".secName");
            var barSecTextTime = updateDynamicText(
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
                    .attr("transform", "translate(" + bstX + " " + bstY + ") rotate(0)")
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
                    return getTimeFromNano(metric.b-metric.a);
                });
                barSecTextTime.transition().call(chartTransition)
                    .attr("text-anchor", "middle")
                    .attr("transform", "translate(" + bsttX + " " + bsttY + ")")
                    .style("fill", textFill)
            }
            
            
            if (barSecTextShouldExist) {
                
                
                barSecText.text(function(metric) {
                    return metric.name;
                });
                
                var barSecTextNode = barSecText.node();
                
                var textLen = barSecTextNode ? barSecTextNode.getComputedTextLength() : 0;
                
                var textVert = textLen > sw-(bstX-sx)*2 && textLen < sh;
                
                var bstOOBSpaceCheck = 10;
                var bstOOBSpacePosition = 10;
                
                if (textVert) bstOOBSpaceCheck += textLen*0.5;
                
                var bstOOB =
                    bstY > y.range()[0] - bstOOBSpaceCheck ? 0 :
                    bstY < y.range()[1] + bstOOBSpaceCheck ? 1 : -1;
                
                if (bstOOB != -1) {
                    bstY = y.range()[bstOOB] + bstOOBSpacePosition * (bstOOB == 0 ? -1 : 1);
                    textVert = false;
                    
                    /*
                    if (!barTextOOB[bstOOB]) barTextOOB[bstOOB] = [];
                    if (!barTextOOB[bstOOB][metric.level]) barTextOOB[bstOOB][metric.level] = 0;
                    var oobTextNum = barTextOOB[bstOOB][metric.level];
                    
                    bstY = y.range()[bstOOB] + oobTextNum * 20 * (bstOOB == 0 ? 1 : -1);
                    
                    barTextOOB[bstOOB][metric.level] = oobTextNum+1;
                    */
                }
                
                bstX += textVert ? -3+sw*0.5 : 5;
                
                var vertAngle = Math.acos(Math.min(sw, sh)/(textLen+40))*180/Math.PI;
                if (isNaN(vertAngle)) vertAngle = 90;
                 
                //console.log(sw, sh, vertAngle);
                
                barSecText.transition().call(chartTransition)
                    //.attr("x", 10)
                    //.attr("y", sh * 0.5 - 0)
                    .attr("height", sh)
                    .attr("dy", (textVert ? 0 : 3))
                    .attr("text-anchor", textVert ? "middle" : "start")
                    .attr("transform", "translate(" + bstX + " " + bstY + ") rotate("+(textVert ? vertAngle : 0)+")")
                    .style("fill", textFill)
                    
                    
            }
            
            if (parent) parent.childNano += metric.a;
            
        });
        
        if (barInfoShouldExist) {
            var barInfoLen = 0;
            barInfoLen = Math.max(barInfoLen, barInfo.select(".nanoTime").text(barTotalDuration.toFixed(3) + " ns").node().getComputedTextLength())
            barInfoLen = Math.max(barInfoLen, barInfo.select(".msTime").text((barTotalDuration * 1e-6).toFixed(3) + " ms").node().getComputedTextLength())
            
            var barInfoHeight = barInfo.node().clientHeight;
            var barInfoAngle = getBoxFitAngle(x.rangeBand(), 100, barInfoLen + 40);
            
            barInfo.transition().call(chartTransition)
                .attr("width", x.rangeBand())
                .attr("height", barInfoHeight)
                .attr("text-anchor", "start")
                .attr("transform", "translate("+Math.sin(barInfoAngle*Math.PI/180)*barInfoHeight+" "+(barMaxY)+") rotate("+barInfoAngle+") ")
                //.attr("dy", "1em")
                //.text(barInfoText)
        }
        
    })
    //*/
    
    // TODO turn sideways - horizontal flame chart
    
    /*
    bars.each(function(bar) {
        d3.select(this).selectAll("rect").each(function(metric) {
            if (metric.parent == -1) {
                d3.select(this)
                    .attr("width", x.rangeBand())
                return;
            }
            var scale = d3.scale.linear().range([0, x.rangeBand()]).domain([0, bar[metric.parent].children]);
            d3.select(this)
                .attr("x", scale(metric.sibling))
                .attr("width", scale(1))
        });
    })
    */
        //.attr("width", x.rangeBand())
        
    /*
    // Tick bar segments, all
    //tickUpdate
        //.attr("transform", function(d) { return "translate(0, "+y(d.value)+")"; })
    barSec.selectAll("rect")
        .attr("y", function(d) { return y(d.value); })
        .attr("width", x.rangeBand())
        .attr("height", function(d) { return height - y(d.value); });
    /*
    // New and old
    update                
        .attr("x", function(d) { return x(d[0].value); })
        .attr("width", x.rangeBand())
        .attr("y", function(d) { return y(d[1].value); })
        .attr("height", function(d) { return height - y(d[1].value); });
    */
    
}

function updateTickLines() {
    for (var fps in tickLines) {
        var tickLine = tickLines[fps];
        tickLine.time = 1e9/tickLine.fps;
        var height = y(tickLine.time);
        tickLine.svg.attr("transform", "translate(0, " + height + ")");
    }
}

/*
var valueHeight = 100;

svgValues
    .attr("class", "tickValues")
    .attr("width", width + margin.left + margin.right)
    .attr("height", valueHeight)
*/