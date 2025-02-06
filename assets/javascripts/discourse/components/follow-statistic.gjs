import { i18n } from "discourse-i18n";

const FollowStatistic = <template>
  <div class="follow-statistic">
    <dt>{{i18n @label}}</dt><dd>{{@total}}</dd>
  </div>
</template>;

export default FollowStatistic;
