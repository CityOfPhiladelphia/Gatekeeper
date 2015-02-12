{extends designs/site.tpl}

{block "title"}Docs &mdash; {$dwoo.parent}{/block}

{block "branding"}
<div class="site-branding title-snug">
    <a href="/">
        <div class="text">{$.server.HTTP_HOST}</div>
    </a>
</div>
{/block}
{block "header-bottom"}{/block}

{block "css"}
    {$dwoo.parent}
    <link href="{versioned_url 'lib/prism/prism.css'}" rel="stylesheet">
    <style>
        input.invalid {
            background-color: red;
            color: white;
        }
    </style>
{/block}

{block "js-bottom"}
    {$dwoo.parent}

    {if !$.get.jsdebug}
        <script src="{Site::getVersionedRootUrl('js/pages/Docs.js')}"></script>
    {/if}

    <script>
        Ext.require('Site.page.Docs');
    </script>

    <script src="{versioned_url 'lib/prism/prism.js'}"></script>
{/block}

{block "content"}
    <?php
        // we need to keep a reference to the top-level document for resolving JSONSchema refs
        $GLOBALS['swaggerDocument'] = $this->scope['swaggerDocument'] = &$this->scope;
    ?>

    {template definition input definitionId=null}
        <?php
            $this->scope['swaggerDocument'] = $GLOBALS['swaggerDocument'];
        ?>

        {$input = Emergence\Swagger\Reader::flattenDefinition($input, $swaggerDocument)}
        {$definitionId = default($definitionId, Emergence\Swagger\Reader::getDefinitionIdFromPath($input._resolvedRef))}

        {if $input.properties}
            <table class="docs-table schema-table">
                {if $definitionId}
                <caption>Model: <a href="#models__{$definitionId|replace:array('/','{','}',' '):array('__','-','-','-')}">{$definitionId}</a></caption>
                {/if}
                <thead>
                    <tr>
                        <th>Name</th>
                        <th>Required</th>
                        <th>Schema</th>
                    </tr>
                </thead>

                <tbody>
                {foreach key=property item=propertyData from=$input.properties}
                    <tr>
                        <td>{$property}</td>
                        <td>{tif is_array($input.required) && in_array($property, $input.required) ? 'Yes' : 'No'}</td>
                        <td>{definition $propertyData}</td>
                    </tr>
                    {if $propertyData.description}
                        <tr>
                            <td colspan="3">{$propertyData.description|escape|markdown}</td>
                        </tr>
                    {/if}
                {/foreach}
                </tbody>
            </table>
        {else}
            {if $input.type == 'array'}
                [<div class="indent">{definition $input.items}</div>]
            {else}
                {$input.type} {if $input.format}({$input.format}){/if}
            {/if}
        {/if}
    {/template}

    {template domIdFromPath path}{$path|replace:array('/','{','}'):array('__','-','-')}{/template}

    <div class="split-view">
        <div class="nav-view">
            <ul class="docs-toc">
                <li><a href="#overview">Overview</a></li>
                <li><a href="#keys">API Keys</a></li>
                <li>
                    <a href="#paths">Paths</a>
                    <ul>
                        {foreach key=path item=pathData from=$paths}
                            <li><a href="#paths{domIdFromPath $path}">{$path}</a></li>
                        {/foreach}
                    </ul>
                </li>
                <li>
                    <a href="#models">Models</a>
                    <ul>
                        {foreach key=model item=modelData from=$definitions}
                            <li><a href="#models__{$model|replace:array('/','{','}',' '):array('__','-','-','-')}">{$model}</a></li>
                        {/foreach}
                    </ul>
                </li>
                <li><a href="#community">Community Code &amp; Uses</a></li>
            </ul>
        </div>

        <div class="detail-view endpoint-docs" data-host="{$host|escape}" data-basepath="{$basePath|escape}" data-schemes="{$schemes|implode:','|escape}">
            <header class="page-header" id="overview">
                <h2 class="header-title"><a href="#overview">{$info.title|escape}</a></h2>
                <div class="header-buttons">
                    <label class="toggle"><input type="checkbox"> Subscribe</label>
                </div>
            </header>

            <div class="lead">{$info.description|escape|markdown}</div>

            <section class="page-section" id="keys">
                <header class="section-header">
                    <h2 class="header-title">API Keys</h2>
                    <div class="header-buttons">
                        <a class="button primary" href="/keys/create">Create</a>
                    </div>
                </header>

                {$Keys = Gatekeeper\Keys\Key::getAll()}
                {foreach item=Key from=$Keys}
                    {$metrics = array(
                        callsTotal = $Key->getMetric(calls-total)
                        ,callsWeek = $Key->getMetric(calls-week)
                        ,callsDayAvg = $Key->getMetric(calls-day-avg)
                        ,endpoints = tif($Key->AllEndpoints, null, $Key->getMetric(endpoints))
                    )}
                    <article class="key">
                        <div class="primary-metric"><strong>{$metrics.callsTotal|number_format} call{tif $metrics.callsTotal != 1 ? s}</strong> all time</div>
                        <div class="details">
                            <header>
                                <h3 class="title">{apiKey $Key}</h3>
                                <div class="meta owner">{if $Key->ContactEmail}
                                    {$recipient = $Key->ContactEmail}
                                    {if $Key->ContactName}
                                        {$recipient = "$Key->ContactName <$recipient>"}
                                    {/if}
                                        <a href="mailto:{$recipient|escape}" title="Contact key owner">{$recipient|escape}</a>
                                    {elseif $Key->ContactName}
                                        {$Key->ContactName}
                                    {/if}
                                </div>
                            </header>
                            <ul class="other-metrics">
                                <li><strong>{$metrics.callsWeek|number_format} call{tif round($metrics.callsWeek) != 1 ? s}</strong> this week</li>
                                <li><strong>{$metrics.callsDayAvg|number_format} call{tif round($metrics.callsDayAvg) != 1 ? s}</strong> avg per day</li>
                                <li><strong>{tif $Key->AllEndpoints ? 'All' : $metrics.endpoints|number_format} endpoint{tif $Key->AllEndpoints || $metrics.endpoints != 1 ? s}</strong> permitted</li>
                            </ul>
                        </div>
                        <footer>
                            <a class="button" href="{$Key->getURL()}/share">Share</a>
                            <a class="button destructive" href="{$Key->getURL()}/delete">Delete</a>
                        </footer>
                    </article>
                {/foreach}
            </section>

            <section class="page-section" id="paths">
                <header class="section-header">
                    <h2 class="header-title">Paths</h2>
                </header>

                {foreach key=path item=pathData from=$paths}
                    <section class="endpoint-path" id="paths{domIdFromPath $path}" data-path="{$path}">
                        <header class="section-header">
                            <h3 class="header-title"><a href="#paths{domIdFromPath $path}">{$path}</a></h3>
                        </header>

                        {foreach key=method item=methodData from=$pathData}
                            <section class="endpoint-path-method indent" id="paths{domIdFromPath $path}___{$method}" data-method="{$method}">
                                <header class="section-header">
                                    <h4 class="header-title"><a href="#paths{domIdFromPath $path}___{$method}"><span class="http-method">{$method}</span> {$path}</a></h4>
                                </header>

                                {$methodData.description|escape|markdown}

                                <div class="indent">
                                    <table class="docs-table parameters-table">
                                        <caption>Parameters</caption>
                                        <thead>
                                            <tr>
                                                <th>Name</th>
                                                <th>Located in</th>
                                                <th>Description</th>
                                                <th>Required</th>
                                                <th>Schema</th>
                                            </tr>
                                        </thead>
    
                                        <tbody>
                                        {foreach item=parameterData from=$methodData.parameters}
                                            <tr {html_attributes_encode $parameterData prefix="data-"}>
                                                <td>{$parameterData.name}</td>
                                                <td>{$parameterData.in}</td>
                                                <td>{$parameterData.description|escape|markdown}</td>
                                                <td>{tif $parameterData.required || $parameterData.in == 'path' ? 'Yes' : 'No'}</td>
                                                <td>{definition $parameterData}</td>
                                            </tr>
                                        {/foreach}
                                        </tbody>
                                    </table>
    
                                    <table class="docs-table responses-table">
                                        <caption>Responses</caption>
                                        <thead>
                                            <tr>
                                                <th>Code</th>
                                                <th>Description</th>
                                                <th>Schema</th>
                                            </tr>
                                        </thead>
    
                                        <tbody>
                                        {foreach key=responseCode item=responseData from=$methodData.responses}
                                            <tr>
                                                <td>{$responseCode}</td>
                                                <td>{$responseData.description|escape|markdown}</td>
                                                <td>{definition $responseData}</td>
                                            </tr>
                                        {/foreach}
                                        </tbody>
                                    </table>
                                </div>
                            </section>
                        {/foreach}
                    </section>
                {/foreach}
            </section>

            <section class="page-section" id="models">
                <header class="section-header">
                    <h2 class="header-title">Models</h2>
                </header>

                {foreach key=definition item=definitionData from=$definitions}
                    <section class="endpoint-model" id="models__{$definition|replace:array('/','{','}',' '):array('__','-','-','-')}">
                        {*dump $definitionData*}
                        {definition $definitionData definitionId=$definition}
                    </section>
                {/foreach}
            </section>
        </div>
    </div>
{/block}