import Chart from "chart.js/auto";

export const MonthlyCostChart = {
  mounted() {
    this.renderChart();
  },
  updated() {
    this.renderChart();
  },
  renderChart() {
    if (this.chart) {
      this.chart.destroy();
    }
    this.el.innerHTML = "";
    const canvas = document.createElement("canvas");
    this.el.appendChild(canvas);
    const ctx = canvas.getContext("2d");
    const chartData = JSON.parse(this.el.dataset.chart);
    this.chart = new Chart(ctx, {
      type: "line",
      data: {
        labels: chartData.map(item => item.month),
        datasets: [{
          label: "Monthly Cost Trend",
          data: chartData.map(item => item.cost),
          borderColor: "rgba(75, 192, 192, 1)",
          backgroundColor: "rgba(75, 192, 192, 0.2)",
          fill: false,
          tension: 0.1,
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
      }
    });
  }
};

export const DailyCostChart = {
  mounted() {
    this.renderChart();
  },
  updated() {
    this.renderChart();
  },
  renderChart() {
    if (this.chart) {
      this.chart.destroy();
    }
    this.el.innerHTML = "";
    const canvas = document.createElement("canvas");
    this.el.appendChild(canvas);
    const ctx = canvas.getContext("2d");
    const chartData = JSON.parse(this.el.dataset.chart);
    this.chart = new Chart(ctx, {
      type: "line",
      data: {
        labels: chartData.map(item => item.date),
        datasets: [{
          label: "Daily Cost Trend",
          data: chartData.map(item => item.cost),
          borderColor: "rgba(153, 102, 255, 1)",
          backgroundColor: "rgba(153, 102, 255, 0.2)",
          fill: false,
          tension: 0.1,
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
      }
    });
  }
};

export const BarChartBreakdown = {
  mounted() {
    this.renderChart();
  },
  updated() {
    this.renderChart();
  },
  renderChart() {
    if (this.chart) {
      this.chart.destroy();
    }
    this.el.innerHTML = "";
    const canvas = document.createElement("canvas");
    this.el.appendChild(canvas);
    const ctx = canvas.getContext("2d");
    const data = JSON.parse(this.el.dataset.chart);
    this.chart = new Chart(ctx, {
      type: "bar",
      data: {
        labels: Object.keys(data),
        datasets: [{
          label: "Cost Breakdown by Service",
          data: Object.values(data),
          backgroundColor: [
            "rgba(255, 99, 132, 0.2)",
            "rgba(54, 162, 235, 0.2)",
            "rgba(255, 206, 86, 0.2)",
            "rgba(75, 192, 192, 0.2)",
            "rgba(153, 102, 255, 0.2)"
          ],
          borderColor: [
            "rgba(255, 99, 132, 1)",
            "rgba(54, 162, 235, 1)",
            "rgba(255, 206, 86, 1)",
            "rgba(75, 192, 192, 1)",
            "rgba(153, 102, 255, 1)"
          ],
          borderWidth: 1,
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          y: {
            beginAtZero: true
          }
        }
      }
    });
  }
};

export const BarChartComparison = {
  mounted() {
    this.renderChart();
  },
  updated() {
    this.renderChart();
  },
  renderChart() {
    if (this.chart) {
      this.chart.destroy();
    }
    this.el.innerHTML = "";
    const canvas = document.createElement("canvas");
    this.el.appendChild(canvas);
    const ctx = canvas.getContext("2d");
    const chartData = JSON.parse(this.el.dataset.chart);
    this.chart = new Chart(ctx, {
      type: "bar",
      data: {
        labels: chartData.labels,
        datasets: [{
          label: "Cost Comparison",
          data: chartData.data,
          backgroundColor: "rgba(255, 159, 64, 0.2)",
          borderColor: "rgba(255, 159, 64, 1)",
          borderWidth: 1,
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          y: { beginAtZero: true }
        }
      }
    });
  }
};

export const PieChartService = {
  mounted() {
    this.renderChart();
  },
  updated() {
    this.renderChart();
  },
  renderChart() {
    if (this.chart) {
      this.chart.destroy();
    }
    this.el.innerHTML = "";
    const canvas = document.createElement("canvas");
    this.el.appendChild(canvas);
    const ctx = canvas.getContext("2d");
    const data = JSON.parse(this.el.dataset.chart);
    this.chart = new Chart(ctx, {
      type: "pie",
      data: {
        labels: Object.keys(data),
        datasets: [{
          label: "Cost Distribution by Service",
          data: Object.values(data),
          backgroundColor: [
            "rgba(255, 99, 132, 0.6)",
            "rgba(54, 162, 235, 0.6)",
            "rgba(255, 206, 86, 0.6)",
            "rgba(75, 192, 192, 0.6)",
            "rgba(153, 102, 255, 0.6)"
          ]
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
      }
    });
  }
}; 