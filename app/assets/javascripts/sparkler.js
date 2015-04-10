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
    var next = canvas.nextElementSibling;

    if (next && next.tagName === 'SCRIPT' && next.getAttribute('type') === 'application/json') {
      var json = JSON.parse(next.innerText);
      var context = canvas.getContext('2d');

      var chartData = chartDataFromJSON(json);
      var options = {
        animation: false,
        datasetFill: false,
        multiTooltipTemplate: "<%= datasetLabel %> – <%= value %>",
        pointHitDetectionRadius: 5,
        scaleBeginAtZero: true,
        tooltipTemplate: "<%= label %>: <%= datasetLabel %> – <%= value %>",
      };

      var chart = new Chart(context).Line(chartData, options);
      // console.log(chart.generateLegend());
    } else {
      log('Error: no data found for canvas.');
    }
  }

  function chartDataFromJSON(json) {
    var index = -1;

    return {
      labels: json.months.map(function(m) {
        return m[1] + '/' + m[0].toString().substring(2);
      }),
      datasets: json.series.map(function(s) {
        index += 1;
        var hue = 360 / json.series.length * index;
        var color = "hsl(" + hue + ", 70%, 60%)";

        return {
          label: s[0],
          data: s[1],
          strokeColor: color,
          pointColor: color,
          pointStrokeColor: "#fff",
          pointHighlightFill: "#fff",
          pointHighlightStroke: color,
        };
      })
    };
  }


  // utilities

  function $(selector) {
    return Array.prototype.slice.apply(document.querySelectorAll(selector));
  }

  function log(text) {
    if (console.log) {
      console.log(text);
    }
  }
})();
