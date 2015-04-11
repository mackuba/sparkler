window.$ = {};

$.find = function(selector, where) {
  var collection = (where || document).querySelectorAll(selector);
  return Array.prototype.slice.apply(collection);
};

$.findOne = function(selector, where) {
  return (where || document).querySelector(selector);
};

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

$.parentSection = function(start) {
  var element = start;

  while (element && element.tagName !== 'SECTION') {
    element = element.parentElement;
  }

  return element;
};

(function() {
  // initialization

  document.addEventListener("DOMContentLoaded", function() {
    initialize();
  });

  function initialize() {
    $.find('.report canvas').forEach(function(canvas) {
      createReport(canvas, 'all');
    });

    $.find('.report nav a').forEach(function(a) {
      a.addEventListener('click', function(e) {
        e.preventDefault();

        var buttons = $.find('a', $.parentSection(a));
        buttons.forEach(function(a) { a.classList.remove('selected') });
        a.classList.add('selected');

        var range = a.getAttribute('data-range');

        if (range === 'month') {
          // TODO
        } else {
          var canvas = $.findOne('canvas', $.parentSection(a));
          createReport(canvas, range);
        }
      });
    });
  }


  // charts

  function createReport(canvas, range) {
    if (!canvas.json) {
      var script = $.findOne('script', $.parentSection(canvas));

      if (!script && script.getAttribute('type') !== 'application/json') {
        $.log('Error: no data found for canvas.');
        return;
      }

      canvas.json = JSON.parse(script.innerText);
    }

    var context = canvas.getContext('2d');
    var percents = (canvas.json.series[0][0] !== "Downloads");
    var showLabel = (canvas.json.series[0][0] !== "Downloads");
    var chartData = chartDataFromJSON(canvas.json, range);

    var options = {
      animation: false,
      bezierCurve: false,
      datasetFill: false,
      multiTooltipTemplate: "<%= datasetLabel %> – " + (percents ? "<%= $.formatPercent(value) %>" : "<%= value %>"),
      pointHitDetectionRadius: 5,
      scaleBeginAtZero: true,
      scaleLabel: "<%= value %>" + (percents ? "%" : ""),
      tooltipTemplate: (
        showLabel ?
        "<%= label %>: <%= datasetLabel %> – " + (percents ? "<%= $.formatPercent(value) %>" : "<%= value %>") :
        "<%= label %>: " + (percents ? "<%= $.formatPercent(value) %>" : "<%= value %>")
      ),
    };

    var chart = new Chart(context).Line(chartData, options);

    if (showLabel) {
      var legend = $.findOne('.legend', $.parentSection(canvas));
      if (legend) {
        legend.innerHTML = chart.generateLegend();
      } else {
        $.log('Error: no legend element found.');
      }
    }
  }

  function chartDataFromJSON(json, range) {
    var index = -1;

    var monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    var labels = json.months.map(function(m) {
      return monthNames[m[1] - 1] + " " + m[0].toString().substring(2);
    });

    var datasets = json.series.map(function(s) {
      index += 1;
      var hue = 360 / json.series.length * index;
      var color = s[0] === "Other" ? "#888" : "hsl(" + hue + ", 70%, 60%)";

      return {
        label: s[0],
        data: s[0] === "Downloads" ? s[1] : s[2],
        strokeColor: color,
        pointColor: color,
        pointStrokeColor: "#fff",
        pointHighlightFill: "#fff",
        pointHighlightStroke: color,
      };
    });

    if (range === 'year') {
      labels = labels.slice(labels.length - 12);

      datasets.forEach(function(dataset) {
        dataset.data = dataset.data.slice(dataset.data.length - 12);
      });
    }

    return {
      labels: labels,
      datasets: datasets
    };
  }
})();
