<template lang="pug">
#dashboard(:class="{ 'fullscreen' : fullscreen }")
  init-dust
  dashboard-title
  dashboard-cards(:query-prop="queryProp")
</template>

<script>
import InitDust from '@/components/InitDust'
import DashboardTitle from '@/components/DashboardTitle'
import DashboardCards from '@/components/DashboardCards'

export default {
  name: 'Dashboard',
  components: {
    InitDust,
    DashboardTitle,
    DashboardCards
  },
  props: {
    queryProp: {
      type: String,
      default: null
    }
  },
  computed: {
    fullscreen () {
      return this.$route.path !== '/'
    }
  }
}
</script>

<style lang="stylus">
#dashboard
  height 100%
  padding 12px 0 24px 24px
  display flex
  flex-direction column
</style>
