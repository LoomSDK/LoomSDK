/// <reference path="../../../../../typings/d3/d3.d.ts"/>
/// <reference path="../../../../../typings/jquery/jquery.d.ts"/>

var tickIds = [];
var ticks = [];
var stream;
var pingTime = 20;
var pinger;
//var colors = ["#3A3232", "#D83018", "#F07848", "#FDFCCE", "#C0D8D8"];
var colors = ["#611824", "#C12F2A", "#FF6540", "#FEDE7B", "#F7FFEE"];
var invertGraph = true;

var timeInitRange = 20000;
var timePos = 0;
var timeRange = timeInitRange;

var minTime = 0;
var maxTime = 0;

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

var margin = {top: 20, right: 20, bottom: 60, left: 60},
    width = 960 - margin.left - margin.right,
    height = 1100 - margin.top - margin.bottom;

var x = d3.scale.ordinal()
    .rangeRoundBands([10, width], 0.1);

var y = d3.scale.linear()
    .range([height, 0])
    
if (invertGraph) y.domain([timePos + timeRange, timePos]); else y.domain([timePos, timePos + timeRange]);

var axisX = d3.svg.axis()
    .orient("bottom");

var axisY = d3.svg.axis()
    .orient("left")

var svgRoot = d3.select("body").append("svg")
    .attr("class", "barChart")
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
    
var svgAxisX = svg.append("g")
    .attr("class", "x axis")
    .attr("transform", "translate(0," + height + ")")
  
var svgAxisY = svg.append("g")
    .attr("class", "y axis")

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
        .attr("class", "fps" + fps);
    svgLine.append("line")
        .attr("x1", 0)
        .attr("x2", width)
        .attr("y1", 0)
        .attr("y2", 0)
        .attr("stroke-dasharray", "5,5")
    svgLine.append("text")
        .attr("x", width)
        .attr("y", -5)
        .style("text-anchor", "end")
        .text(fps+" fps");
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
    ticks.push({ metrics: tick.ranges, visibleMetrics: null, maxLevel: 0 });
    updateMaxLevel(ticks[ticks.length-1]);
    sortMetrics(ticks[ticks.length-1]);
    tickIds.push(tick.values[0].value);
    
    updateMetricData();
}

var barZoom = d3.behavior.zoom()
    //.y(d3.scale.linear().domain([margin.y, height]).range([0, timeInitRange]))
    .y(y)
    .on("zoom", barZoomed)
    
d3.select("svg").call(barZoom);

function barZoomed() {
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
    //console.log(tick)
    tick.visibleMetrics = tick.metrics.filter(function(metric, index, metrics) {
        //console.log(metric.a, metric.b, minTime, maxTime)
        metric.oob = metric.a > maxTime || metric.b < minTime
        if (metric.a > maxTime || metric.b < minTime) return false;
        if (y(metric.b) - y(metric.a) < 1) return false;
        return true;
    })
    return tick;
}

function updateMetricData() {
    
    tickIds = tickIds.slice(-60);
    ticks = ticks.slice(-60);
    
    if (tickIds.length >= 1) stream.close();
    
    //x.domain(data.map(function(d) { return d.id; }));
    //x.domain(data.map(function(d) { return d[0].value; }));
    x.domain(tickIds);
    //y.domain([0, d3.max(data, function(d) { return d.tickNano; })]);
    
    axisX.scale(x);
    axisY.scale(y)
    svgAxisX.call(axisX).selectAll("text")
        .style("text-anchor", "end")
        .attr("transform", "rotate(-45)")
        .attr("dx", "-1em")
        .attr("dy", "-0.2em")
    ;
    svgAxisY.call(axisY);
    
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
    
    var bars = svgBars.selectAll(".bar").data(ticks.map(cullMetrics))
    
    //*/
    
    // Only new ones
    /*
    update.enter().append("rect")
        .attr("class", "bar")
    */
    
    // Tick bars, new only, group inside of a bar
    var barGroup = bars.enter().append("g")
        .attr("class", "bar")
    
    bars.exit().remove()
    
    // Tick bars, all
    bars
        .attr("transform", function(metrics, index) { return "translate(" +x(tickIds[index])+", 0)"; })
    
    //bars.each(cullMetrics);
    
    // Tick bar sections, new
    var barSecAll = bars.selectAll(".bs")
        .data(function(tick) {
            return tick.visibleMetrics;
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
        
        //var barTextOOB = [];
        
        d3.select(this).selectAll(".bs").each(function(metric, index) {
            
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
            
            var sx = secX(metric.level);
            var sy = invertGraph ? ay : by;
            var sw = fillLevels ?
                    secX(maxLevel - metric.level) :
                    metric.parent == -1 ? x.rangeBand() : secX(1);
            var sh = dy;
            
            var barSec = d3.select(this);
            
            //barSec.attr("transform", "translate("+sx+", "+sy+")")
            
            barSec.select("rect")
                .attr("x", sx)
                .attr("y", sy)
                .attr("width", sw)
                .attr("height", Math.max(1, sh))
                .style("fill", function(metric, i) {
                    return colorFromDuration(metric.b - metric.a);
                })
                //.style("fill", metric.oob ? "#FF0000" : "#0000FF")
            
            var barSecText = barSec.select("text");
            var barSecTextExists = barSecText.size() > 0;
            var barSecTextShouldExist = sh > 15;
            
            if (!barSecTextExists && barSecTextShouldExist) {
                barSecText = barSec.append("text")
            }
            
            if (barSecTextExists && !barSecTextShouldExist) barSecText.remove();
            
            if (barSecTextShouldExist) {
                
                
                barSecText.text(function(metric) { return metric.name });
                
                var rectLab = d3.lab(barSec.select("rect").style("fill"))
                
                var barSecTextNode = barSecText.node();
                
                var textLen = barSecTextNode ? barSecTextNode.getComputedTextLength() : 0;
                
                var bstX = sx + 10;
                var bstY = sy + sh*0.5;
                
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
                
                barSecText
                    //.attr("x", 10)
                    //.attr("y", sh * 0.5 - 0)
                    .attr("height", sh)
                    .attr("dy", (textVert ? sw*0.5-5 : 3))
                    .attr("text-anchor", textVert ? "middle" : "left")
                    .attr("transform", "translate(" + bstX + " " + bstY + ") rotate("+(textVert ? 90 : 0)+")")
                    .style("fill", rectLab.l > 80 ? "darkgray" : rectLab.brighter(3))
                    
            }
            
            if (parent) parent.childNano += metric.a;
            
        });
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
        tickLine.time = 1e6/tickLine.fps;
        var height = y(tickLine.time);
        tickLine.svg.attr("transform", "translate(0, " + height + ")");
    }
}
 
 /*           
function fetchGridData() {
    var gridArrayData = [];
    // show loading message
    $.ajax({
        url: "/tick",
        success: function (result) {
            if (result.status != "success") {
                console.log("Result error: "+result);
                return;
            }
            gridArrayData.push(result.data.metrics);
            addTick(result.data.metrics);
            // set the new data
            $("#tickMetrics").jqGrid('setGridParam', { data: gridArrayData});
            // refresh the grid
            $("#tickMetrics").trigger('reloadGrid');
        }
    });
}
*/