{# Import global parameters that source from grains and pillars #}
{% import 'params.jinja' as params %}

{% pkg_name = 'salt-{1}-x86_64.pkg'.format(params.salt_version) %}
{% set repo_url = 'https://repo.saltstack.com/{0}osx/{1}' %}
{% set repo_url = repo_url.format(params.dev, pkg_name) %}
{% set tmp_dir = '/tmp/pkg/' %}
{% set pkg_location = tmp_dir + pkg_name %}

get-pkg:
  file.managed:
    - name: {{ tmp_dir }}
    - makedirs: True
    - source: {{ repo_url }}
    - skip_verify: True

install_pkg:
  cmd.run:
    - name: installer -pkg {{ pkg_location }}

configur_minion:
  cmd.run:
    - name: salt-config -i {{ params.minion_id }} -m {{ params.master_ip }}
