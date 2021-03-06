<template lang="pug">
.graph(:class="{ visible: data.labels.length > 0 }")
  histogram(
    :chart-data="data"
    :options="options"
    ref="localHistogram"
  )
</template>

<script>
import Histogram from '@/components/cards/dust/Histogram'
import moment from 'moment'
import { COLORS, THRESHOLDS, DEFAULT_FRAME } from '@/config'

const OVERFLOW = 500

export default {
  name: 'Graph',
  props: ['histogram', 'particle'],
  components: { Histogram },
  data: () => ({
    gradient: null
  }),
  computed: {
    th () {
      return THRESHOLDS[this.particle][DEFAULT_FRAME]
    },
    ratios () {
      return this.th.map(v => v / this.max)
    },
    max () {
      return this.th[this.th.length - 1] + OVERFLOW
    },
    annotations () {
      let annotations = []
      for (let i = 0; i < this.th.length; i++) {
        annotations.push({
          type: 'line',
          drawTime: 'afterDatasetsDraw',
          mode: 'horizontal',
          scaleID: 'y-axis-0',
          value: this.th[i],
          borderColor: 'transparent',
          borderWidth: 1,
          borderDash: [5, 1],
          label: {
            enabled: true,
            content: (this.th[i] >= 100 ? this.th[i] + ' –' : this.th[i] + ' —'),
            backgroundColor: '#FFF',
            position: 'left',
            fontSize: 9,
            fontColor: '#444',
            fontStyle: 'normal',
            xPadding: 4,
            yPadding: 2,
            xAdjust: -4
          }
        })
      }
      return annotations
    },
    data () {
      return {
        labels: this.histogram.date.map(d => moment(d).format('h A')),
        datasets: [{
          data: this.histogram[this.particle].map(v => v.toFixed(2)),
          backgroundColor: this.gradient,
          borderColor: this.gradient,
          fill: false
        }]
      }
    },
    options () {
      return {
        legend: false,
        responsive: true,
        maintainAspectRatio: false,
        tooltips: {
          intersect: false,
          cornerRadius: 3,
          displayColors: false,
          callbacks: {
            label: (tooltipItem) => {
              var label = tooltipItem.yLabel
              if (parseFloat(label) <= 0.1)
                label = 'No data'

              return label
            }
          }
        },
        animation: {
          duration: 0,
          easing: 'linear'
        },
        elements: {
          point: {
            radius: 0,
            hoverRadius: 0
          },
          line: {
            borderWidth: 2,
            fill: false
          }
        },
        scales: {
          xAxes: [{
            gridLines: {
              display: false,
              drawBorder: false,
              zeroLineColor: 'transparent'
            },
            ticks: {
              maxRotation: 0,
              fontSize: 10,
              source: 'data'
            }
          }],
          yAxes: [{
            display: false,
            type: 'logarithmic',
            gridLines: {
              display: false,
              drawBorder: false
            },
            ticks: {
              min: 0,
              max: this.max,
              autoSkip: false
            }
          }]
        },
        annotation: { annotations: this.annotations }
      }
    }
  },
  methods: {
    generateGradient () {
      let canvas = this.$refs.localHistogram.$refs.canvas
      let chart = this.$refs.localHistogram.$data._chart

      let yAxis = chart.scales['y-axis-0']
      let minValueYPixel = yAxis.getPixelForValue(0)
      let maxValueYPixel = yAxis.getPixelForValue(this.max)
      this.gradient = canvas.getContext('2d').createLinearGradient(0, minValueYPixel, 0, maxValueYPixel)

      let curColor = COLORS[0]
      this.gradient.addColorStop(0, curColor)
      for (let i = 0; i < this.th.length; i++) {
        let pc = 1 - (yAxis.getPixelForValue(this.th[i]) / minValueYPixel)
        pc = pc < 0 ? 0 : pc
        pc = pc > 1 ? 1 : pc

        this.gradient.addColorStop(pc, curColor)
        curColor = COLORS[i + 1]
        this.gradient.addColorStop(pc, curColor)
      }
      // Overflow
      // this.gradient.addColorStop(this.ratios[this.ratios.length - 1], COLORS[COLORS.length - 1])
      // this.gradient.addColorStop(1, COLORS[COLORS.length - 1])
    }
  },
  watch: {
    histogram: {
      handler: function () {
        this.generateGradient()
      },
      deep: true
    }
  },
  mounted () {
    this.generateGradient()
    window.addEventListener('resize', this.generateGradient)
  },
  beforeDestroy () {
    window.removeEventListener('resize', this.generateGradient)
  }
}
</script>

<style lang="stylus">
.graph
  width 100%
  height 100%
  position relative
  opacity 0

  -webkit-transition opacity 1s ease-in-out
  -moz-transition opacity 1s ease-in-out
  -ms-transition opacity 1s ease-in-out
  -o-transition opacity 1s ease-in-out
  transition opacity 1s ease-in-out

  &.visible
    opacity 1

  div
    width 100%
    height 100%

    canvas
      max-height 100% !important
</style>
