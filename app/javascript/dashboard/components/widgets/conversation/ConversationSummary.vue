<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAccount } from 'dashboard/composables/useAccount';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import TasksAPI from 'dashboard/api/captain/tasks';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  conversationId: {
    type: [Number, String],
    required: true,
  },
});

const { t } = useI18n();
const { isCloudFeatureEnabled } = useAccount();
const { formatMessage } = useMessageFormatter();

const isExpanded = ref(false);
const isLoading = ref(false);
const summary = ref('');
const error = ref('');

const captainTasksEnabled = computed(() => {
  return isCloudFeatureEnabled(FEATURE_FLAGS.CAPTAIN_TASKS);
});

const formattedSummary = computed(() => {
  return summary.value ? formatMessage(summary.value) : '';
});

const fetchSummary = async () => {
  isLoading.value = true;
  error.value = '';
  try {
    const result = await TasksAPI.summarize(props.conversationId);
    const {
      data: { message: generatedMessage },
    } = result;
    summary.value = generatedMessage || '';
  } catch (e) {
    if (e.name !== 'AbortError' && e.name !== 'CanceledError') {
      error.value = e.response?.data?.error || t('CHAT_LIST.SUMMARY.ERROR');
    }
  } finally {
    isLoading.value = false;
  }
};

const toggleSummary = async () => {
  if (isExpanded.value) {
    isExpanded.value = false;
    return;
  }
  isExpanded.value = true;
  if (!summary.value && !error.value) {
    await fetchSummary();
  }
};

const onButtonClick = e => {
  e.stopPropagation();
  toggleSummary();
};

defineExpose({
  isExpanded,
  isLoading,
  summary,
  error,
  formattedSummary,
  captainTasksEnabled,
});
</script>

<template>
  <Button
    v-if="captainTasksEnabled"
    icon="i-material-symbols-auto-awesome"
    slate
    ghost
    xs
    :title="t('CHAT_LIST.SUMMARY.TITLE')"
    class="opacity-0 group-hover:opacity-100 transition-opacity"
    :class="{ '!opacity-100': isExpanded }"
    @click="onButtonClick"
  />
</template>
