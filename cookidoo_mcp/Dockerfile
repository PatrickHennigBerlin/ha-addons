ARG BUILD_FROM
FROM $BUILD_FROM

# Upstream: https://github.com/nodomain/mcp-cookidoo (MIT), fest auf einen geprüften Stand gepinnt
ARG MCP_COOKIDOO_REF=b097330

RUN apk add --no-cache git tailscale \
    && git clone https://github.com/nodomain/mcp-cookidoo /opt/mcp-cookidoo \
    && git -C /opt/mcp-cookidoo checkout "${MCP_COOKIDOO_REF}" \
    && rm -rf /opt/mcp-cookidoo/.git \
    && apk del git

# Land und Sprache sind upstream fest auf die Schweiz verdrahtet; hier per Umgebungsvariable einstellbar
RUN sed -i 's/get_localization_options(country="ch", language="de-CH")/get_localization_options(country=os.getenv("COOKIDOO_COUNTRY", "ch"), language=os.getenv("COOKIDOO_LANGUAGE", "de-CH"))/' \
        /opt/mcp-cookidoo/cookidoo_service.py \
    && grep -q 'os.getenv("COOKIDOO_COUNTRY"' /opt/mcp-cookidoo/cookidoo_service.py

# Upstream ist gegen eine ältere cookidoo-api geschrieben. Ab 0.18 heißt die Token-Erneuerung
# refresh() und die Restlaufzeit steht in _expires_at statt expires_in.
RUN sed -i 's/_cookidoo_api\.expires_in/(_cookidoo_api._expires_at - __import__("time").time())/; s/_cookidoo_api\.refresh_token()/_cookidoo_api.refresh()/' \
        /opt/mcp-cookidoo/server.py \
    && sed -i 's/self\._api_client\.refresh_token()/self._api_client.refresh()/g' /opt/mcp-cookidoo/cookidoo_service.py \
    && ! grep -n '_cookidoo_api\.expires_in\|await .*refresh_token()' /opt/mcp-cookidoo/server.py /opt/mcp-cookidoo/cookidoo_service.py

# Upstream entfernt mit lstrip alle führenden Ziffern eines Schritts, also auch die Zeit
# ("3 Min./120°C/Stufe 1" wird zu "Min./..."). Nur echte Aufzählungen wie "1." oder "-" entfernen.
RUN sed -i 's/step\.strip()\.lstrip("0123456789\.)-• \\t")/re.sub(r"^(\\d+[.)]|[-•])\\s+", "", step.strip())/' /opt/mcp-cookidoo/server.py \
    && grep -q 're.sub(r"^(\\d+\[.)\]|\[-•\])' /opt/mcp-cookidoo/server.py

COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt && rm /tmp/requirements.txt

COPY rootfs /
RUN chmod a+x /run.sh

WORKDIR /opt/mcp-cookidoo
CMD [ "/run.sh" ]
