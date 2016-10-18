{% set salt_version = salt['pillar.get']('salt_version', '') %}
{% set upgrade_salt_version = salt['pillar.get']('upgrade_salt_version', '') %}
{% set repo_pkg = salt['pillar.get']('repo_pkg', '') %}
{% set latest = salt['pillar.get']('latest', '') %}
{% set dev = salt['pillar.get']('dev', '') %}
{% set dev = dev + '/' if dev else '' %}
{% set cloud_profile = salt['pillar.get']('cloud_profile', '') %}
{% set orch_master = salt['pillar.get']('orch_master', '') %}
{% set username = salt['pillar.get']('username', '') %}
{% set upgrade = salt['pillar.get']('upgrade', '') %}
{% set clean = salt['pillar.get']('clean', '') %}
{% set mac_parallels_host = salt['pillar.get']('mac:mac_parallels_host', '') %}
{% set mac_parallels_user = salt['pillar.get']('mac:mac_parallels_user', '') %}
{% set mac_parallels_passwd = salt['pillar.get']('mac:mac_parallels_passwd', '') %}
{% set mac_master_name = salt['pillar.get']('mac:mac_master_name', '') %}
{% set mac_master_profile = salt['pillar.get']('mac:mac_master_profile', '') %}
{% set mac_minion_passwd = salt['pillar.get']('mac:mac_minion_passwd', '') %}
{% set mac_minion_user = salt['pillar.get']('mac:mac_minion_user', '') %}
{% set mac_parallels_vm = 'pkg-el-capitan-' + salt_version %}
{% set hosts = [] %}

{% macro destroy_vm() -%}
stop_parallels_clone:
  salt.function:
    - name: parallels.stop
    - tgt: 'qapkgtest-mac-parallels-test'
    - arg:
      - capitan-pkg-test-{{ salt_version }}
    - kwarg:
        kill: True
        runas: parallels

destroy_parallels_clone:
  salt.function:
    - name: parallels.delete
    - tgt: 'qapkgtest-mac-parallels-test'
    - arg:
      - capitan-pkg-test-{{ salt_version }}
    - kwarg:
        runas: parallels
        linked: True

{% endmacro %}

{# Note: install sshpass if using sudo and runas #}
{% macro create_vm(salt_version, action='None', upgrade_val='False') -%}
setup_mac_on_master:
  salt.state:
    - tgt: {{ orch_master }}
    - sls:
      - test_orch.states.setup_mac_on_master
    - pillar:
        mac_parallels_host: {{ mac_parallels_host }}
        mac_parallels_user: {{ mac_parallels_user }}
        mac_parallels_passwd: {{ mac_parallels_passwd }}
    - require_in:
      - salt: create_parallels_clone

create_parallels_clone:
  salt.function:
    - name: parallels.clone
    - tgt: 'qapkgtest-mac-parallels-test'
    - arg:
      - pkg-el-capitan-base
      - pkg-el-capitan-{{ salt_version }}
    - kwarg:
        runas: parallels
    - ssh: 'true'
    - require_in:
      - salt: start_parallels_clone
      - salt: create_linux_master
      - salt: sleep_before_verify
      - salt: verify_ssh_hosts

start_parallels_clone:
  salt.function:
    - name: parallels.start
    - tgt: 'qapkgtest-mac-parallels-test'
    - arg:
      - pkg-el-capitan-{{ salt_version }}
    - kwarg:
        runas: parallels
    - ssh: 'true'

sleep_before_mac_reactor:
  salt.function:
    - name: test.sleep
    - tgt: {{ orch_master }}
    - arg:
      - 60

setup_mac_reactor:
  salt.state:
    - tgt: {{ orch_master }}
    - sls:
      - test_orch.states.setup_mac_reactor_sls
    - pillar:
        salt_version: {{ salt_version }}
        dev: {{ dev }}
        orch_master: {{ orch_master }}
        mac_minion_passwd: {{ mac_minion_passwd }}
        mac_minion_user: {{ mac_minion_user }}

create_linux_master:
  salt.function:
    - name: salt_cluster.create_node
    - tgt: {{ orch_master }}
    - arg:
      - {{ mac_master_name }}
      - {{ mac_master_profile }}
    - require_in:
      - salt: sleep_before_verify
      - salt: verify_ssh_hosts

sleep_before_verify:
  salt.function:
    - name: test.sleep
    - tgt: {{ orch_master }}
    - arg:
      - 120

verify_ssh_hosts:
  salt.function:
    - name: cmd.run
    - tgt: {{ orch_master }}
    - arg:
      - salt-ssh '*' -i test.ping

test_install_salt_mac_master:
  salt.state:
    - tgt: {{ mac_master_name }}
    - tgt_type: list
    - ssh: 'true'
    - sls:
      - test_install.saltstack
    - pillar:
        salt_version: {{ salt_version }}
        dev: {{ dev }}
        latest: {{ latest }}
        repo_pkg: {{ repo_pkg }}
        upgrade: {{ upgrade_val }}

{%- endmacro %}

{% macro test_run(salt_version, action='None', upgrade_val='False') -%}
test_run_{{ action }}:
  salt.state:
    - tgt: '{{ mac_master_name }}'
    - tgt_type: glob
    - ssh: 'true'
    - sls:
      - test_run.mac
    - pillar:
        salt_version: {{ salt_version }}
        dev: {{ dev }}
{%- endmacro %}


{% if clean %}
{{ create_vm(salt_version, action='clean') }}
{# {{ test_run(salt_version, action='clean') }}
{{ destroy_vm() }} #}
{% endif %}
