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
      <#assign status  = node.getAttributeValue("_status","")>
      <#if (status == "complete") || (status == "verified")>
        <#assign qid  = node.getQualifiedId()>
        <#assign desc = node.description>
---id:   ${qid}
        <#if locationsList?has_content>
          <#list locationsList as location>
--location:  ${location}
          </#list>
        </#if>
        <#local attributes = node.getAttributeKeys()/>
        <#list attributes as attr>
          <#if (attr[0] != '_')>
          <#local value = node.getAttributeValue(attr,"")/>
--attr[${attr}]: ${value}
          </#if>
        </#list>
${desc}
      </#if>
    </#if>
    <#if (hasChild!0) != 0>
        <#list childrenList as child>
            <@showreq child/>
        </#list>
    </#if>
</#macro>
<@showreq rootReq/>
