{% for name, config in pillar.get('rvm', {}).items() %}
{%- if config == None -%}
{%- set config = {} -%}
{%- endif -%}
{%- set user = salt['pillar.get']('users:' + name, {}) -%}
{%- set home = user.get('home', "/home/%s" % name) -%}

{%- if 'prime_group' in user and 'name' in user['prime_group'] %}
{%- set group = user.prime_group.name -%}
{%- else -%}
{%- set group = name -%}
{%- endif %}

{%- set installs = config.get('installs', ['2']) %}
{%- set default = config.get('default', '2') %}

rvm_{{ name }}_install:
  cmd.run:
    - name: |
       \curl -sSL https://get.rvm.io | bash -s stable
    - creates: {{ home }}/.rvm
    - shell: "/bin/bash"
    - require:
      - pkg: rvm_deps

rvm_{{ name }}_configure:
  cmd.run:
    - name: |
        {%- for version in installs %}
        rvm install {{ version }};
        {%- endfor %}
        rvm alias default {{ default }};
    - shell: "/bin/bash"
    - require:
      - cmd: rvm_{{ name }}_install
  file.directory:
    - name: {{ home }}/.rvm
    - user: {{ name }}
    - group: {{ group }}
    - recurse:
      - user
      - group
    - require:
      - group: users_{{ name }}_user
      - user: users_{{ name }}_user
      - cmd: rvm_{{ name }}_configure

{% endfor %}

rvm_deps:
  pkg.installed:
    - pkgs:
      - build-essential
      - libssl-dev
      - curl
