(function() {
  // initialization

  document.addEventListener("DOMContentLoaded", function() {
    initialize();
  });

  function initialize() {
    $.find('section.feed').forEach(function(feed) {
      feed.addEventListener('click', function(e) {
        if (e.target.tagName === 'A' && e.target.className === 'reload') {
          e.preventDefault();

          var a = e.target;
          if (a.innerText === '...') {
            return;
          }

          a.innerText = '...';

          $.ajax({
            url: a.href,
            success: function(response) {
              feed.innerHTML = response;
            },
            error: function() {
              a.innerText = 'Try again';
            }
          });
        }
      });
    });

    $.find('.report canvas').forEach(function(canvas, i) {
      var title = $.findOne('h2', $.parentSection(canvas));
      createReport(canvas, 'all', title.innerText !== "Total downloads");
    });

    $.find('.report nav a').forEach(function(a) {
      a.addEventListener('click', function(e) {
        e.preventDefault();

        var section = $.parentSection(a);

        var buttons = $.find('a', section);
        buttons.forEach(function(a) { a.classList.remove('selected') });
        a.classList.add('selected');

        var checkbox = $.findOne('.denormalize', section);
        var title = $.findOne('h2', section);

        var canvas = $.findOne('canvas', section);
        createReport(canvas, a.getAttribute('data-range'),
          (!checkbox || !checkbox.checked) && title.innerText !== "Total downloads");
      });
    });

    $.find('.report .denormalize').forEach(function(checkbox) {
      checkbox.addEventListener('change', function() {
        var section = $.parentSection(checkbox);
        var selectedMode = $.findOne('a.selected', section).getAttribute('data-range');
        var canvas = $.findOne('canvas', section);
        createReport(canvas, selectedMode, !checkbox.checked);
      });
    });
  }


  // charts

  function createReport(canvas, range, normalized) {
    if (canvas.chart) {
      canvas.chart.destroy();
      delete canvas.chart;
    }

    if (!canvas.json) {
      var script = $.findOne('script', $.parentSection(canvas));

      if (!script && script.getAttribute('type') !== 'application/json') {
        $.log('Error: no data found for canvas.');
        return;
      }

      canvas.json = JSON.parse(script.innerText);
    }

    var context = canvas.getContext('2d');
    var showLabel = (canvas.json.series[0][0] !== "Downloads");

    if (range === 'month') {
      var chartData = pieChartDataFromJSON(canvas.json, normalized);

      var options = {
        animateRotate: false,
        animation: false,
        tooltipTemplate: "<%= label %>: " + (normalized ? "<%= $.formatPercent(value) %>" : "<%= value %>")
      };

      canvas.chart = new Chart(context).Pie(chartData, options);
    } else {
      var chartData = lineChartDataFromJSON(canvas.json, range, normalized);

      var options = {
        animation: false,
        bezierCurve: false,
        datasetFill: false,
        multiTooltipTemplate: "<%= datasetLabel %> – " + (normalized ? "<%= $.formatPercent(value) %>" : "<%= value %>"),
        pointHitDetectionRadius: 5,
        scaleBeginAtZero: true,
        scaleLabel: "<%= value %>" + (normalized ? "%" : ""),
        tooltipTemplate: (
          showLabel ?
          "<%= label %>: <%= datasetLabel %> – " + (normalized ? "<%= $.formatPercent(value) %>" : "<%= value %>") :
          "<%= label %>: " + (normalized ? "<%= $.formatPercent(value) %>" : "<%= value %>")
        ),
      };

      canvas.chart = new Chart(context).Line(chartData, options);
    }

    if (showLabel) {
      var legend = $.findOne('.legend', $.parentSection(canvas));
      if (legend) {
        legend.innerHTML = canvas.chart.generateLegend();
      } else {
        $.log('Error: no legend element found.');
      }
    }
  }

  function lineChartDataFromJSON(json, range, normalized) {
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
        data: normalized ? (s.length > 2 ? s[2] : s[1]) : s[1],
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

  function pieChartDataFromJSON(json, normalized) {
    var index = -1;

    return json.series.map(function(s) {
      index += 1;
      var hue = 360 / json.series.length * index;
      var color = s[0] === "Other" ? "#888" : "hsl(" + hue + ", 70%, 60%)";
      var highlight = s[0] === "Other" ? "#aaa" : "hsl(" + hue + ", 70%, 70%)";

      var amounts = normalized ? (s.length > 2 ? s[2] : s[1]) : s[1];

      return {
        label: s[0],
        value: amounts[amounts.length - 1],
        color: color,
        highlight: highlight
      };
    })
  }
})();
