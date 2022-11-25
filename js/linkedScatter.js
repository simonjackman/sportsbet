// !preview r2d3 data=toJSON(data_for_d3,dataframe="rows"), container="div", elementId = "linkedScatter"

var gap = {cols: 40, rows: 70};
var margin = {top: 20, right: 16, bottom: 22, left: 20},
    panel_height = height;
    panel_width = width/2;

var pdata = [];
pdata[0] = data.data.filter(function(d){ return(d.outcomes_collapsed=="LNP"); });
pdata[1] = data.data.filter(function(d){ return(d.outcomes_collapsed=="ALP"); });

var yhat = [];
yhat[0] = data.yhat.filter(function(d){ return(d.outcomes_collapsed=="LNP"); });
yhat[1] = data.yhat.filter(function(d){ return(d.outcomes_collapsed=="ALP"); });

var labels = [ "Coalition", "Labor"];

var xmax = [100, 100];
var ymax = [100, 100];

var gmax = 100;
var gref_max = 100;
var gmin = 0;
var grange = gmax - gmin;
var extend = 0.025;
var gup = gmax + (extend * grange);
var glo = 0;

var xScale = d3.scaleLinear()
    .range([margin.left, panel_width-margin.left-margin.right])
    .domain([25, 75]);

var yScale = d3.scaleLinear()
    .range([panel_height-margin.top-margin.bottom,margin.top])
    .domain([0, 100]);

//console.log(yScale(gmax)-yScale(gmin));

var fmt = d3.format("3.1f");

var formatAsPercentage = d3.format(".0p");

var tip = d3.tip()
      .attr('class', 'd3-tip')
      .offset([-7, 0])
      .html(function(event,d) {
        return d.Division + " (" + d.State + ")" + "<br>" +
          "TCP:" + " " + fmt(d.votes) + "<br>" +
          "Prob:" + " " + fmt(d.prob) + "<br>" +
          "Price:" + " " + d3.format("4.2f")(d.prices) + "<br>";
/*        "<table class='linkedScatter_tab'>" +
          "<tr><td style='text-align: center;' colspan='2'>" +
          d.Division + " (" + d.State + ")" + "</td></tr>" +
          "<tr><td>TCP:</td>" + "<td>" + fmt(d.votes) + "</td></tr>" +
          "<tr><td>Prob:</td>" + fmt(d.prob) + "</td></tr>" +
          "<tr><td>Price:</td>" + d3.format("4.2f")(d.prices) + "</td></tr>" +
          "</table>";
          */
      });

var svgMaster = d3.select("#linkedScatter")
  .append("svg")
  .attr("width",width)
  .attr("height",height)
  .style("display","block");

svgMaster.call(tip);

// overall svg
var svgList = [ ];
var gam = [ ];

// two panels side by side
svgList[0] = svgMaster
    .append("svg")
    .attr("id", "svg1")
    .attr("height", panel_height)
    .attr("width", panel_width);

svgList[1] = svgMaster
    .append("g")
    .attr("transform", "translate(" + panel_width + ")" )
    .append("svg")
    .attr("id", "svg2")
    .attr("height", panel_height)
    .attr("width", panel_width);

// add axes to each SVG
var yTicks = d3.range(0, 100, 25);
var xTicks = d3.range(25, 75, 5);

function make_x_grid(){
  return d3.axisBottom(xScale);
}

function make_y_grid(){
  return d3.axisLeft(yScale);
}

var lineGenerator = d3.line()
            .x(d => xScale(d.votes))
            .y(d => yScale(d.pred));

for(var j = 0; j < 2; j++) {

   svgList[j].append("g")
    .attr("class", "grid")
    //.style("opacity",0.10)
    .attr("transform","translate(0," + margin.top + ")")
    .call(make_x_grid()
      .ticks(10)
      .tickSize(panel_height-margin.bottom-margin.top-12)
      )
    .call(g => g.select(".domain").remove());

    svgList[j].append("g")
    .attr("class", "grid")
    //.style("opacity",0.10)
    .attr("transform","translate(" + margin.left + ", 0)")
    .call(make_y_grid()
      .tickValues([0,25,50,75,100])
      .tickSize(-panel_width+margin.right+margin.left+22)
      )
      .call(g => g.select(".domain").remove());


    //xGridLines(j,xTicks);
    //yGridLines(j,yTicks);

    // add ref degree lines
    svgList[j].append("g")
    .append("svg:line")
    .attr("x1",xScale(50))
    .attr("x2",xScale(50))
    .attr("y1",yScale(0))
    .attr("y2",yScale(100))
    .style("stroke","#666");

    svgList[j].append("g")
    .append("svg:line")
    .attr("x1",xScale(25))
    .attr("x2",xScale(75))
    .attr("y1",yScale(50))
    .attr("y2",yScale(50))
    .style("stroke","#666");

    // panel title
    svgList[j].append("g")
        .attr("class","panel-title")
        .append("text")
        .attr("x",xScale(50))
        .attr("y",margin.top - 5)
        .text(labels[j])
        .attr("text-anchor","middle");

    // y axis label
    svgList[j].append("g")
      .append("text")
      .text("↑ IPOW")
      .attr("x",xScale(24.5))
      .attr("y",yScale(97))
      .attr("text-anchor","start");
      //.attr("transform","translate(24,24)");

  gam[j] = svgList[j].append("path")
    .attr("class","line")
    .style("fill","none")
    .style("stroke","blue")
    .datum(yhat[j])
    .attr("d",lineGenerator);

    // plot y vs x in first plot
    svgList[j].selectAll("circle")
    .data(pdata[j])
    .enter()
    .append("circle")
    .attr("cx", function(d) { return xScale(d.votes); })
    .attr("cy", function(d) { return yScale(d.prob); })
    .attr("j",j)
    .attr("class", function(d) { return "pt" + "_" + j + "_" + d.i; })
    .attr("r", 3)
    .style("stroke", "black")
    .style("fill", "#A3A3A3")
    .on("mouseover",
      function(event,d){
        d3.select(this).style("fill","orange").attr("r",8);
        tip.show(event,d);
        // highlight the data point in the "other" panel
        var this_j = d3.select(this).attr("j");
        var other_j = (this_j == 0) ? 1 : 0;
        var this_i = d.i;
        var e = pdata[other_j].filter(function(d){ return d.i == this_i; });
        var other_d = Array.from(e.values());
        var other_i = other_d[0].i;
        console.log("class of the other i: " + ".pt_" + other_j + "_" + other_i);
        d3.select(".pt_" + other_j + "_" + other_i).style("fill","orange").attr("r",8);
      })
    .on("mouseout",
    function(event,d){
      d3.select(this).style("fill","#A3A3A3").attr("r",3);
      tip.hide(event,d);

      var this_j = d3.select(this).attr("j");
      var other_j = (this_j == 0) ? 1 : 0;
      var this_i = d.i;
      var other_d = Array.from(pdata[other_j].filter(function(d){ return d.i == this_i; }).values());
      var other_i = other_d[0].i;
      d3.select(".pt_" + other_j + "_" + other_i).style("fill","#A3A3A3").attr("r",3);
    });

svgList[j].append("g")
    .append("text")
    .attr("x",xScale(50))
    .attr("y",yScale(-12))
    .text("TCP vote (%), 2019 or notional")
    .attr("text-anchor","middle");

}
