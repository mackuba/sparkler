function $(selector) {
  return Array.prototype.slice.apply(document.querySelectorAll(selector));
}

$.log = function(text) {
  if (console.log) {
    console.log(text);
  }
};

$.formatPercent = function(value) {
  var int = Math.floor(value);
  var rest = value - int;
  return int + '.' + (rest > 0 ? rest.toString().substr(2, 1) : '0') + '%';
};

(function() {
  // initialization

  document.addEventListener("DOMContentLoaded", function() {
    initialize();
  });

  function initialize() {
    $('canvas.report').forEach(function(canvas) {
      createReport(canvas);
    });
  }


  // charts

  function createReport(canvas) {
    var script = canvas.nextElementSibling;

    if (script && script.tagName === 'SCRIPT' && script.getAttribute('type') === 'application/json') {
      var json = JSON.parse(script.innerText);
      var context = canvas.getContext('2d');

      var chartData = chartDataFromJSON(json);
      var options = {
        animation: false,
        datasetFill: false,
        multiTooltipTemplate: "<%= datasetLabel %> – <%= $.formatPercent(value) %>",
        pointHitDetectionRadius: 5,
        scaleBeginAtZero: true,
        scaleLabel: "<%= value %>%",
        tooltipTemplate: "<%= label %>: <%= datasetLabel %> – <%= $.formatPercent(value) %>",
      };

      var chart = new Chart(context).Line(chartData, options);

      var legend = script.nextElementSibling;
      if (legend && legend.tagName === 'DIV' && legend.className === 'legend') {
        legend.innerHTML = chart.generateLegend();
      } else {
        $.log('Error: no legend element found.');
      }
    } else {
      $.log('Error: no data found for canvas.');
    }
  }

  function chartDataFromJSON(json) {
    var index = -1;

    var totals = [];
    for (var i = 0; i < json.months.length; i++) {
      var sum = 0;
      for (var s = 0; s < json.series.length; s++) {
        sum += json.series[s][1][i];
      }
      totals.push(Math.max(sum, 1));
    }

    var months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    return {
      labels: json.months.map(function(m) {
        return months[m[1] - 1] + " " + m[0].toString().substring(2);
      }),
      datasets: json.series.map(function(s) {
        index += 1;
        var hue = 360 / json.series.length * index;
        var color = "hsl(" + hue + ", 70%, 60%)";

        return {
          label: s[0],
          data: s[1].map(function(d, i) { return d * 100 / totals[i] }),
          strokeColor: color,
          pointColor: color,
          pointStrokeColor: "#fff",
          pointHighlightFill: "#fff",
          pointHighlightStroke: color,
        };
      })
    };
  }
})();
