add_mac_reactor_file:
  file.managed:
    - name: /srv/reactor/mac_reactor.sls
    - source: salt://test_orch/reactor/mac_reactor
    - template: jinja
    - makedirs: True
