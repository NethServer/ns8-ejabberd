<!--
  Copyright (C) 2023 Nethesis S.r.l.
  SPDX-License-Identifier: GPL-3.0-or-later
-->
<template>
  <cv-grid fullWidth>
    <cv-row>
      <cv-column class="page-title">
        <h2>{{ $t("settings.title") }}</h2>
      </cv-column>
    </cv-row>
    <cv-row v-if="error.getConfiguration">
      <cv-column>
        <NsInlineNotification
          kind="error"
          :title="$t('action.get-configuration')"
          :description="error.getConfiguration"
          :showCloseButton="false"
        />
      </cv-column>
    </cv-row>
    <cv-row>
      <cv-column>
        <cv-tile light>
          <cv-skeleton-text
            v-if="loading.getConfiguration || loading.getDefaults"
            heading
            paragraph
            :line-count="15"
            width="80%"
          ></cv-skeleton-text>
          <cv-form v-else @submit.prevent="configureModule">
            <NsTextInput
              :label="$t('settings.hostname')"
              :placeholder="$t('settings.hostname_placeholder')"
              v-model="hostname"
              class="mg-bottom"
              :invalid-message="error.hostname"
              :disabled="loading.getConfiguration || loading.configureModule"
              ref="hostname"
              tooltipAlignment="center"
              tooltipDirection="right"
            >
              <template slot="tooltip">
                <div
                  v-html="
                    $t(
                      'settings.hostname_must_be_relevant_for_user_authentication'
                    )
                  "
                ></div>
              </template>
            </NsTextInput>
            <NsComboBox
              v-model.trim="ldap_domain"
              :autoFilter="true"
              :autoHighlight="true"
              :title="$t('settings.ldap_domain')"
              :label="$t('settings.choose_ldap_domain')"
              :options="domains_list"
              :acceptUserInput="false"
              :showItemType="true"
              :invalid-message="$t(error.ldap_domain)"
              :disabled="loading.getConfiguration || loading.configureModule"
              tooltipAlignment="start"
              tooltipDirection="top"
              ref="ldap_domain"
            >
              <template slot="tooltip">
                {{ $t("settings.choose_the_ldap_domain_to_use") }}
              </template>
            </NsComboBox>
            <cv-toggle
              value="letsEncrypt"
              :label="$t('settings.request_https_certificate')"
              v-model="isLetsEncryptEnabled"
              :disabled="loading.getConfiguration || loading.configureModule"
              class="mg-bottom"
            >
              <template slot="text-left">{{
                $t("settings.disabled")
              }}</template>
              <template slot="text-right">{{
                $t("settings.enabled")
              }}</template>
            </cv-toggle>
            <!-- advanced options -->
            <cv-accordion ref="accordion" class="maxwidth mg-bottom">
              <cv-accordion-item :open="toggleAccordion[0]">
                <template slot="title">{{ $t("settings.advanced") }}</template>
                <template slot="content">
                  <NsToggle
                    :label="$t('settings.webadmin_status')"
                    value="webadmin"
                    :form-item="true"
                    v-model="webadmin"
                    :disabled="
                      loading.getConfiguration || loading.configureModule
                    "
                    ref="webadmin"
                  >
                    <template slot="tooltip">
                      <span v-html="$t('settings.admin_login_tips')"></span>
                    </template>
                    <template slot="text-left">{{
                      $t("settings.disabled")
                    }}</template>
                    <template slot="text-right">{{
                      $t("settings.enabled")
                    }}</template>
                  </NsToggle>
                  <template v-if="webadmin">
                    <template v-if="hostname"> </template>
                    <NsButton
                      kind="ghost"
                      class="mg-left"
                      :icon="Launch20"
                      :disabled="loading.getConfiguration"
                      @click="goToEjabberdWebAdmin"
                    >
                      {{ $t("settings.open_ejabberd_webapp") }}
                    </NsButton>
                    <cv-text-area
                      :label="$t('settings.adminList')"
                      v-model.trim="adminsList"
                      :invalid-message="error.adminsList"
                      :helper-text="$t('settings.Write_administrator_list')"
                      :value="adminsList"
                      class="maxwidth textarea mg-left"
                      ref="adminsList"
                      :placeholder="$t('settings.Write_administrator_list')"
                      :disabled="
                        loading.getConfiguration || loading.configureModule
                      "
                    >
                    </cv-text-area>
                  </template>
                  <cv-toggle
                    value="s2s"
                    :label="$t('settings.Enable_federation_s2s')"
                    v-model="isS2sEnabled"
                    :disabled="
                      loading.getConfiguration || loading.configureModule
                    "
                    class="mg-bottom"
                  >
                    <template slot="text-left">{{
                      $t("settings.disabled")
                    }}</template>
                    <template slot="text-right">{{
                      $t("settings.enabled")
                    }}</template>
                  </cv-toggle>
                  <cv-toggle
                    value="mod_mam_status"
                    :label="
                      $t('settings.Enable_message_archive_management_mod_mam')
                    "
                    v-model="isModMamStatus"
                    :disabled="
                      loading.getConfiguration || loading.configureModule
                    "
                    class="mg-bottom"
                  >
                    <template slot="text-left">{{
                      $t("settings.disabled")
                    }}</template>
                    <template slot="text-right">{{
                      $t("settings.enabled")
                    }}</template>
                  </cv-toggle>
                  <template v-if="isModMamStatus">
                    <NsSlider
                      :disabled="
                        loading.getConfiguration || loading.configureModule
                      "
                      :label="$t('settings.purge_mnesia_database_interval')"
                      class="mg-left"
                      v-model="purge_mnesia_interval"
                      min="1"
                      max="365"
                      step="1"
                      stepMultiplier="10"
                      minLabel=""
                      maxLabel=""
                      showUnlimited
                      :isUnlimited="isPurgeMnesiaUnlimited"
                      :unlimitedLabel="$t('settings.never')"
                      :limitedLabel="$t('settings.specify_duration')"
                      :invalidMessage="error.purge_mnesia_interval"
                      :unitLabel="$t('settings.days')"
                      @unlimited="isPurgeMnesiaUnlimited = $event"
                    />
                  </template>
                  <cv-toggle
                    value="http_upload"
                    :label="$t('settings.Enable_file_upload_mod_http_upload')"
                    v-model="isHttpUploadEnabled"
                    :disabled="
                      loading.getConfiguration || loading.configureModule
                    "
                    class="mg-bottom"
                  >
                    <template slot="text-left">{{
                      $t("settings.disabled")
                    }}</template>
                    <template slot="text-right">{{
                      $t("settings.enabled")
                    }}</template>
                  </cv-toggle>
                  <template v-if="isHttpUploadEnabled">
                    <NsSlider
                      :disabled="
                        loading.getConfiguration || loading.configureModule
                      "
                      :label="$t('settings.purge_httpd_upload_interval')"
                      class="mg-left"
                      v-model="purge_httpd_upload_interval"
                      min="1"
                      max="365"
                      step="1"
                      stepMultiplier="10"
                      minLabel=""
                      maxLabel=""
                      showUnlimited
                      :isUnlimited="isModHttpUploadUnlimited"
                      :unlimitedLabel="$t('settings.never')"
                      :limitedLabel="$t('settings.specify_duration')"
                      :invalidMessage="error.purge_httpd_upload_interval"
                      :unitLabel="$t('settings.days')"
                      @unlimited="isModHttpUploadUnlimited = $event"
                    />
                  </template>
                  <NsByteSlider
                    v-model="shaper_normal"
                    :label="$t('settings.shaper_normal_kbytes/s')"
                    min="1"
                    max="30000"
                    step="1"
                    stepMultiplier="1"
                    minLabel=""
                    maxLabel=""
                    :isUnlimited="false"
                    :byteUnit="$t('settings.bytes_per_seconds')"
                    tagKind="high-contrast"
                    :invalidMessage="$t(error.shaper_normal)"
                    :disabled="
                      loading.getConfiguration || loading.configureModule
                    "
                  />
                  <NsByteSlider
                    v-model="shaper_fast"
                    :label="$t('settings.shaper_fast_kbytes/s')"
                    min="1"
                    max="30000"
                    step="1"
                    stepMultiplier="1"
                    minLabel=""
                    maxLabel=""
                    :isUnlimited="false"
                    :byteUnit="$t('settings.bytes_per_seconds')"
                    tagKind="high-contrast"
                    :invalidMessage="$t(error.shaper_fast)"
                    :disabled="
                      loading.getConfiguration || loading.configureModule
                    "
                  />
                </template>
              </cv-accordion-item>
            </cv-accordion>
            <cv-row v-if="error.configureModule">
              <cv-column>
                <NsInlineNotification
                  kind="error"
                  :title="$t('action.configure-module')"
                  :description="error.configureModule"
                  :showCloseButton="false"
                />
              </cv-column>
            </cv-row>
            <NsButton
              kind="primary"
              :icon="Save20"
              :loading="loading.configureModule"
              :disabled="loading.getConfiguration || loading.configureModule"
              >{{ $t("settings.save") }}</NsButton
            >
          </cv-form>
        </cv-tile>
      </cv-column>
    </cv-row>
  </cv-grid>
</template>

<script>
import to from "await-to-js";
import { mapState } from "vuex";
import {
  QueryParamService,
  UtilService,
  TaskService,
  IconService,
  PageTitleService,
} from "@nethserver/ns8-ui-lib";

export default {
  name: "Settings",
  mixins: [
    TaskService,
    IconService,
    UtilService,
    QueryParamService,
    PageTitleService,
  ],
  pageTitle() {
    return this.$t("settings.title") + " - " + this.appName;
  },
  data() {
    return {
      q: {
        page: "settings",
      },
      urlCheckInterval: null,
      hostname: "",
      isLetsEncryptEnabled: false,
      adminsList: "",
      isS2sEnabled: false,
      isHttpUploadEnabled: false,
      isModMamStatus: false,
      isModHttpUploadUnlimited: true,
      shaper_normal: "50000",
      shaper_fast: "100000",
      domains_list: [],
      ldap_domain: "",
      isPurgeMnesiaUnlimited: false,
      purge_mnesia_interval: "30",
      purge_httpd_upload_interval: "31",
      webadmin: false,
      loading: {
        getConfiguration: false,
        configureModule: false,
      },
      error: {
        getConfiguration: "",
        configureModule: "",
        hostname: "",
        ldap_domain: "",
        adminsList: "",
        s2s: "",
        http_upload: "",
        mod_mam_status: "",
        mod_http_upload_unlimited: "",
        shaper_normal: "",
        shaper_fast: "",
        purge_mnesia_unlimited: "",
        lets_encrypt: "",
        purge_mnesia_interval: "",
        purge_httpd_upload_interval: "",
      },
    };
  },
  computed: {
    ...mapState(["instanceName", "core", "appName"]),
  },
  beforeRouteEnter(to, from, next) {
    next((vm) => {
      vm.watchQueryData(vm);
      vm.urlCheckInterval = vm.initUrlBindingForApp(vm, vm.q.page);
    });
  },
  beforeRouteLeave(to, from, next) {
    clearInterval(this.urlCheckInterval);
    next();
  },
  created() {
    this.getConfiguration();
  },
  methods: {
    goToEjabberdWebAdmin() {
      window.open(`https://${this.hostname}` + ":5280/admin/", "_blank");
    },
    async getConfiguration() {
      this.loading.getConfiguration = true;
      this.error.getConfiguration = "";
      const taskAction = "get-configuration";
      const eventId = this.getUuid();

      // register to task error
      this.core.$root.$once(
        `${taskAction}-aborted-${eventId}`,
        this.getConfigurationAborted
      );

      // register to task completion
      this.core.$root.$once(
        `${taskAction}-completed-${eventId}`,
        this.getConfigurationCompleted
      );

      const res = await to(
        this.createModuleTaskForApp(this.instanceName, {
          action: taskAction,
          extra: {
            title: this.$t("action." + taskAction),
            isNotificationHidden: true,
            eventId,
          },
        })
      );
      const err = res[0];

      if (err) {
        console.error(`error creating task ${taskAction}`, err);
        this.error.getConfiguration = this.getErrorMessage(err);
        this.loading.getConfiguration = false;
        return;
      }
    },
    getConfigurationAborted(taskResult, taskContext) {
      console.error(`${taskContext.action} aborted`, taskResult);
      this.error.getConfiguration = this.$t("error.generic_error");
      this.loading.getConfiguration = false;
    },
    getConfigurationCompleted(taskContext, taskResult) {
      const config = taskResult.output;
      this.hostname = config.hostname;
      this.isLetsEncryptEnabled = config.lets_encrypt;
      this.adminsList = config.adminsList.split(",").join("\n");
      this.isS2sEnabled = config.s2s;
      this.isHttpUploadEnabled = config.http_upload;
      this.isModMamStatus = config.mod_mam_status;
      this.isModHttpUploadUnlimited = config.mod_http_upload_unlimited;
      this.shaper_normal = String(config.shaper_normal / 1024);
      this.shaper_fast = String(config.shaper_fast / 1024);
      this.domains_list = config.domains_list;
      this.isPurgeMnesiaUnlimited = config.purge_mnesia_unlimited;
      this.purge_mnesia_interval = String(config.purge_mnesia_interval);
      this.purge_httpd_upload_interval = String(
        config.purge_httpd_upload_interval
      );
      this.webadmin = config.webadmin;
      // force to reload value after dom update
      this.$nextTick(() => {
        this.ldap_domain = config.ldap_domain;
      });
      this.loading.getConfiguration = false;
      this.focusElement("hostname");
    },
    validateConfigureModule() {
      this.clearErrors(this);
      let isValidationOk = true;

      if (!this.hostname) {
        this.error.hostname = this.$t("settings.required");

        if (isValidationOk) {
          this.focusElement("hostname");
          isValidationOk = false;
        }
      }

      if (!this.ldap_domain) {
        this.error.ldap_domain = this.$t("settings.required");

        if (isValidationOk) {
          this.focusElement("ldap_domain");
          isValidationOk = false;
        }
      }
      //Validate an email login form
      function validateEmail(email) {
        var re = /\S+@\S+\.\S+/;
        return re.test(email);
      }

      if (this.adminsList) {
        const array = this.adminsList.split("\n");
        array.forEach((element) => {
          var email = validateEmail(element.trim());
          if (!email) {
            this.error.adminsList =
              this.$t("settings.bad_email_address") + " ' " + element + " '";
            this.focusElement("adminsList");
            isValidationOk = false;
          }
        });
      }
      //validate normal speed < fast speed
      if (parseInt(this.shaper_normal) > parseInt(this.shaper_fast)) {
        this.error.shaper_normal = "error.shaper_normal_must_be_inferior_to_shaper_fast";
        this.shaper_normal = this.shaper_fast;
        if (isValidationOk) {
          this.focusElement("shaper_normal");
        }
        isValidationOk = false;
      }
      return isValidationOk;
    },
    configureModuleValidationFailed(validationErrors) {
      this.loading.configureModule = false;

      for (const validationError of validationErrors) {
        const param = validationError.parameter;

        // set i18n error message
        this.error[param] = this.$t("settings." + validationError.error);
      }
    },
    async configureModule() {
      const isValidationOk = this.validateConfigureModule();
      if (!isValidationOk) {
        return;
      }

      this.loading.configureModule = true;
      const taskAction = "configure-module";
      const eventId = this.getUuid();

      // register to task error
      this.core.$root.$once(
        `${taskAction}-aborted-${eventId}`,
        this.configureModuleAborted
      );

      // register to task validation
      this.core.$root.$once(
        `${taskAction}-validation-failed-${eventId}`,
        this.configureModuleValidationFailed
      );

      // register to task completion
      this.core.$root.$once(
        `${taskAction}-completed-${eventId}`,
        this.configureModuleCompleted
      );

      const res = await to(
        this.createModuleTaskForApp(this.instanceName, {
          action: taskAction,
          data: {
            hostname: this.hostname,
            ldap_domain: this.ldap_domain,
            adminsList: this.adminsList.split("\n").join(",").toLowerCase(),
            s2s: this.isS2sEnabled,
            http_upload: this.isHttpUploadEnabled,
            mod_mam_status: this.isModMamStatus,
            mod_http_upload_unlimited: this.isModHttpUploadUnlimited,
            shaper_normal: parseInt(this.shaper_normal) * 1024,
            shaper_fast: parseInt(this.shaper_fast) * 1024,
            purge_mnesia_unlimited: this.isPurgeMnesiaUnlimited,
            lets_encrypt: this.isLetsEncryptEnabled,
            purge_mnesia_interval: parseInt(this.purge_mnesia_interval),
            purge_httpd_upload_interval: parseInt(
              this.purge_httpd_upload_interval
            ),
            webadmin: this.webadmin,
          },
          extra: {
            title: this.$t("settings.configure_instance", {
              instance: this.instanceName,
            }),
            description: this.$t("settings.processing"),
            eventId,
          },
        })
      );
      const err = res[0];

      if (err) {
        console.error(`error creating task ${taskAction}`, err);
        this.error.configureModule = this.getErrorMessage(err);
        this.loading.configureModule = false;
        return;
      }
    },
    configureModuleAborted(taskResult, taskContext) {
      console.error(`${taskContext.action} aborted`, taskResult);
      this.error.configureModule = this.$t("error.generic_error");
      this.loading.configureModule = false;
    },
    configureModuleCompleted() {
      this.loading.configureModule = false;

      // reload configuration
      this.getConfiguration();
    },
  },
};
</script>

<style scoped lang="scss">
@import "../styles/carbon-utils";
.mg-left {
  margin-left: 2rem;
}
.maxwidth {
  max-width: 38rem;
}
.mg-bottom {
  margin-bottom: $spacing-06;
}
</style>
