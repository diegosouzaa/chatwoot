<script setup>
import { ref, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAccount } from 'dashboard/composables/useAccount';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import TasksAPI from 'dashboard/api/captain/tasks';
import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const props = defineProps({
  conversationId: {
    type: [Number, String],
    required: true,
  },
});

const { t } = useI18n();
const { isCloudFeatureEnabled } = useAccount();
const { formatMessage } = useMessageFormatter();

const isLoading = ref(false);
const summary = ref('');
const error = ref('');
const hasFetched = ref(false);

const captainTasksEnabled = computed(() => {
  return isCloudFeatureEnabled(FEATURE_FLAGS.CAPTAIN_TASKS);
});

const formattedSummary = computed(() => {
  return summary.value ? formatMessage(summary.value) : '';
});

const fetchSummary = async () => {
  if (!captainTasksEnabled.value || hasFetched.value) return;

  isLoading.value = true;
  error.value = '';
  hasFetched.value = true;

  try {
    const result = await TasksAPI.summarize(props.conversationId);
    const {
      data: { message: generatedMessage },
    } = result;
    summary.value = generatedMessage || '';
  } catch (e) {
    if (e.name !== 'AbortError' && e.name !== 'CanceledError') {
      error.value =
        e.response?.data?.error || t('CONVERSATION_SIDEBAR.SUMMARY.ERROR');
    }
  } finally {
    isLoading.value = false;
  }
};

const refetch = () => {
  hasFetched.value = false;
  summary.value = '';
  error.value = '';
  fetchSummary();
};

watch(
  () => props.conversationId,
  () => {
    hasFetched.value = false;
    summary.value = '';
    error.value = '';
  }
);

defineExpose({
  fetchSummary,
  captainTasksEnabled,
});
</script>

<template>
  <div v-if="captainTasksEnabled" class="p-3">
    <div v-if="isLoading" class="flex items-center justify-center py-4">
      <Spinner :size="20" class="text-n-slate-10" />
    </div>

    <div v-else-if="error" class="text-sm text-n-ruby-11">
      {{ error }}
      <Button
        :label="t('CONVERSATION_SIDEBAR.SUMMARY.RETRY')"
        size="sm"
        variant="link"
        class="ml-2"
        @click="refetch"
      />
    </div>

    <div v-else-if="!hasFetched" class="flex flex-col items-center gap-3 py-2">
      <p class="text-sm text-n-slate-11 text-center mb-0">
        {{ t('CONVERSATION_SIDEBAR.SUMMARY.DESCRIPTION') }}
      </p>
      <Button
        :label="t('CONVERSATION_SIDEBAR.SUMMARY.GENERATE')"
        icon="i-material-symbols-auto-awesome"
        size="sm"
        @click="fetchSummary"
      />
    </div>

    <div
      v-else-if="summary"
      class="summary-content text-sm text-n-slate-11 animate-fade-in [&_ul]:list-disc [&_ul]:pl-4 [&_ol]:list-decimal [&_ol]:pl-4 [&_li]:my-1 [&_p]:my-2 [&_p:first-child]:mt-0 [&_p:last-child]:mb-0 [&_strong]:text-n-slate-12"
      v-html="formattedSummary"
    />

    <div v-else class="text-sm text-n-slate-11 py-2">
      {{ t('CONVERSATION_SIDEBAR.SUMMARY.EMPTY') }}
    </div>

    <div
      v-if="hasFetched && !isLoading && !error"
      class="mt-3 pt-3 border-t border-n-weak"
    >
      <Button
        :label="t('CONVERSATION_SIDEBAR.SUMMARY.REGENERATE')"
        icon="i-lucide-refresh-cw"
        size="sm"
        variant="faded"
        color="slate"
        @click="refetch"
      />
    </div>
  </div>
</template>

<style scoped>
.animate-fade-in {
  animation: fadeIn 0.3s ease-in-out;
}

@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(-4px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
</style>
