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
    var hasPercentages = (title.innerText !== "Total feed downloads");

    $.find('canvas', report).forEach(function(canvas) {
      createChart(canvas, 'all', hasPercentages);
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
    var section = $.parentSection(link);

    var buttons = $.find('a', section);
    buttons.forEach(function(a) { a.classList.remove('selected') });
    link.classList.add('selected');

    var checkbox = $.findOne('.denormalize', section);
    var title = $.findOne('h2', section);
    var hasPercentages = (title.innerText !== "Total feed downloads") && (!checkbox || !checkbox.checked);

    var canvas = $.findOne('canvas', section);
    createChart(canvas, link.getAttribute('data-range'), hasPercentages);
  }

  function onDenormalizeCheckboxChange(event) {
    var checkbox = event.target;
    var section = $.parentSection(checkbox);
    var selectedMode = $.findOne('a.selected', section).getAttribute('data-range');
    var canvas = $.findOne('canvas', section);

    createChart(canvas, selectedMode, !checkbox.checked);
  }

  function createChart(canvas, range, normalized) {
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
    var showLabel = (canvas.json.series[0].title !== "Downloads");
    var valueFormat = normalized ? "<%= $.formatPercent(value) %>" : "<%= value %>";

    if (range === 'month') {
      var chartData = pieChartDataFromJSON(canvas.json, normalized);

      var options = {
        animateRotate: false,
        animation: false,
        tooltipTemplate: "<%= label %>: " + valueFormat
      };

      canvas.chart = new Chart(context).Pie(chartData, options);
    } else {
      var chartData = lineChartDataFromJSON(canvas.json, range, normalized);

      var options = {
        animation: false,
        bezierCurve: false,
        datasetFill: false,
        multiTooltipTemplate: "<%= datasetLabel %> – " + valueFormat,
        pointHitDetectionRadius: 5,
        scaleBeginAtZero: true,
        scaleLabel: "<%= value %>" + (normalized ? "%" : ""),
        tooltipTemplate: (
          showLabel ? ("<%= label %>: <%= datasetLabel %> – " + valueFormat) : ("<%= label %>: " + valueFormat)
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
    var labels = json.months.map(function(ym) {
      var yearMonth = ym.split('-');
      var year = yearMonth[0];
      var month = parseInt(yearMonth[1], 10);

      return MONTH_NAMES[month - 1] + " " + year.substring(2);
    });

    var datasets = json.series.map(function(s, index) {
      var color = datasetColor(s.title, index, json.series.length);
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
      var color = datasetColor(s.title, index, json.series.length);
      var highlight = highlightColor(s.title, index, json.series.length);

      return {
        label: s.title,
        value: amounts[amounts.length - 1],
        color: color,
        highlight: highlight
      };
    })
  }

  function datasetColor(label, index, total) {
    if (label === 'Other') {
      return '#999';
    } else {
      var hue = 360 / total * index;
      return "hsl(" + hue + ", 70%, 60%)";
    }
  }

  function highlightColor(label, index, total) {
    if (label === 'Other') {
      return '#aaa';
    } else {
      var hue = 360 / total * index;
      return "hsl(" + hue + ", 70%, 70%)";
    }
  }

})();
