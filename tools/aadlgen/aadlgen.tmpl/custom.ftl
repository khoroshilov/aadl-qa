<#--
/* Copyright 2009-2012 ISPRAS (http://www.ispras.ru), UniTESK Lab (http://www.unitesk.com)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
 -->
<#macro showreq req>
    <#local node = req/>
    <#local childrenList = node.getSortedChildren()/>
    <#list childrenList as child>
        <#local hasChild = 1/>
    </#list>
    <#local locationsList = node.getParent().getAttributeValue("_locations","")/>
    <#if node.getType() == "TestPurpose">
<#assign qid  = node.getQualifiedId()>
<#assign desc = node.description>
    <#if first == 0>
    </#if>
---id:   ${qid}
    <#list locationsList as location>
--location:  ${location}
    </#list>
${desc}
<#assign first  = 0>
    </#if>
    <#if (hasChild!0) != 0>
        <#list childrenList as child>
            <@showreq child/>
        </#list>
    </#if>
</#macro>
<#assign first  = 1>
<@showreq rootReq/>
