(function() {
  // initialization

  document.addEventListener("DOMContentLoaded", function() {
    initialize();
  });

  function initialize() {
    $.find('section.feed').forEach(function(feed) {
      initializeFeedCard(feed);
    });

    $.find('#new_feed, #edit_feed').forEach(function(form) {
      initializeFeedForm(form);
    });

    $.find('.report').forEach(function(report) {
      initializeReport(report);
    });
  }


  // feeds page

  function initializeFeedCard(feed) {
    feed.addEventListener('click', onFeedClick);
  }

  function onFeedClick(event) {
    if (event.target.tagName === 'A' && event.target.classList.contains('reload')) {
      event.preventDefault();

      var reloadLink = event.target;
      var feed = event.currentTarget;
      reloadFeed(reloadLink, feed);
    }
  }

  function reloadFeed(reloadLink, feed) {
    reloadLink.style.display = 'none';

    var spinner = reloadLink.nextElementSibling;
    spinner.style.display = 'inline';

    $.ajax({
      url: reloadLink.href,
      success: function(response) {
        feed.innerHTML = response;
      },
      error: function() {
        spinner.style.display = 'none';
        reloadLink.style.display = 'inline';
        reloadLink.innerText = 'Try again';
      }
    });
  }


  // feed forms

  function initializeFeedForm(form) {
    $.find('#feed_title', form).forEach(function(input) {
      input.addEventListener('change', onFeedTitleChange);
    });

    $.find('#feed_public_stats', form).forEach(function(stats) {
      stats.addEventListener('change', onFeedPublicStatsChange);
      updateCountsCheckbox(stats);
    });
  }

  function onFeedTitleChange(event) {
    var titleField = event.target;
    var nameField = $.findOne('#feed_name');

    if (nameField.value == "") {
      nameField.value = titleField.value.toLowerCase().replace(/\W+/g, '_');
    }
  }

  function onFeedPublicStatsChange(event) {
    var statsCheckbox = event.target;
    updateCountsCheckbox(statsCheckbox);
  }

  function updateCountsCheckbox(statsCheckbox) {
    var countsCheckbox = $.findOne('#feed_public_counts');

    countsCheckbox.disabled = !statsCheckbox.checked;
    countsCheckbox.checked = statsCheckbox.checked && countsCheckbox.checked;
  }


  // stats page

  var MONTH_NAMES = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  function initializeReport(report) {
    var title = $.findOne('h2', report);

    $.find('canvas', report).forEach(function(canvas) {
      canvas.range = canvas.getAttribute('data-range');
      canvas.normalized = (canvas.getAttribute('data-normalized') === 'true');
      canvas.showLabels = (canvas.getAttribute('data-labels') === 'true');

      createChart(canvas);
    });

    $.find('nav a', report).forEach(function(a) {
      a.addEventListener('click', onChartModeLinkClick);
    });

    $.find('.denormalize', report).forEach(function(checkbox) {
      checkbox.addEventListener('change', onDenormalizeCheckboxChange);
    });
  }

  function onChartModeLinkClick(event) {
    event.preventDefault();

    var link = event.target;
    selectOnlyLink(link);

    var canvas = $.findOne('canvas', $.parentSection(link));
    canvas.range = link.getAttribute('data-range');

    createChart(canvas);
  }

  function onDenormalizeCheckboxChange(event) {
    var checkbox = event.target;

    var canvas = $.findOne('canvas', $.parentSection(checkbox));
    canvas.normalized = !checkbox.checked;

    createChart(canvas);
  }

  function selectOnlyLink(link) {
    var allLinks = $.find('a', link.parentElement);
    allLinks.forEach(function(a) { a.classList.remove('selected') });
    link.classList.add('selected');
  }

  function createChart(canvas) {
    if (canvas.chart) {
      canvas.chart.destroy();
      delete canvas.chart;
    }

    if (!canvas.json) {
      var script = $.findOne('script', $.parentSection(canvas));

      if (!script || script.getAttribute('type') !== 'application/json') {
        $.log('Error: no data found for canvas.');
        return;
      }

      canvas.json = JSON.parse(script.innerText);
    }

    var context = canvas.getContext('2d');

    var fracValueFormat = canvas.normalized ? "<%= $.formatPercent(value) %>" : "<%= value %>";
    var intValueFormat = canvas.normalized ? "<%= value %>%" : "<%= value %>";

    if (canvas.range === 'month') {
      var chartData = pieChartDataFromJSON(canvas.json, canvas.normalized);

      canvas.chart = new Chart(context).Pie(chartData, {
        animateRotate: false,
        animation: false,
        tooltipTemplate: "<%= label %>: " + fracValueFormat
      });
    } else {
      var chartData = lineChartDataFromJSON(canvas.json, canvas.range, canvas.normalized);

      canvas.chart = new Chart(context).Line(chartData, {
        animation: false,
        bezierCurve: false,
        datasetFill: false,
        multiTooltipTemplate: "<%= datasetLabel %> – " + fracValueFormat,
        pointHitDetectionRadius: 5,
        scaleBeginAtZero: true,
        scaleLabel: intValueFormat,
        tooltipTemplate: (
          canvas.showLabels ?
          ("<%= label %>: <%= datasetLabel %> – " + fracValueFormat) :
          ("<%= label %>: " + fracValueFormat)
        ),
      });
    }

    if (canvas.showLabels) {
      var legend = $.findOne('.legend', $.parentSection(canvas));
      if (legend) {
        legend.innerHTML = canvas.chart.generateLegend();
      } else {
        $.log('Error: no legend element found.');
      }
    }
  }

  function lineChartDataFromJSON(json, range, normalized) {
    var labels = json.months.map(function(ym) {
      var yearMonth = ym.split('-');
      var year = yearMonth[0];
      var month = parseInt(yearMonth[1], 10);

      return MONTH_NAMES[month - 1] + " " + year.substring(2);
    });

    var datasets = json.series.map(function(s, index) {
      var color = datasetColor(s, index, json.series.length);
      var amounts = normalized && s.normalized || s.amounts;

      return {
        label: s.title,
        data: amounts,
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
    return json.series.map(function(s, index) {
      var amounts = normalized && s.normalized || s.amounts;
      var color = datasetColor(s, index, json.series.length);
      var highlight = highlightColor(s, index, json.series.length);

      return {
        label: s.title,
        value: amounts[amounts.length - 1],
        color: color,
        highlight: highlight
      };
    })
  }

  function datasetColor(series, index, total) {
    if (series.is_other) {
      return '#999';
    } else {
      var hue = 360 / total * index;
      return "hsl(" + hue + ", 70%, 60%)";
    }
  }

  function highlightColor(series, index, total) {
    if (series.is_other) {
      return '#aaa';
    } else {
      var hue = 360 / total * index;
      return "hsl(" + hue + ", 70%, 70%)";
    }
  }

})();
