-- 1. 选择字段
create table advertisement
(
    ad_id               varchar(10) null,
    xyz_campaign_id     varchar(10) null,
    fb_campaign_id      varchar(10) null,
    age                 varchar(10) null,
    gender              varchar(10) null,
    interest            int         null,
    Impressions         int         null,
    Clicks              int         null,
    Spent               float       null,
    Total_Conversion    int         null,
    Approved_Conversion int         null
);
-- 2. 删除重复值
CREATE TABLE new_advertisement
SELECT DISTINCT *
FROM advertisement;
-- 3. 缺失值处理
SELECT  SUM(IF(ad_id IS NULL, 1, 0))                 AS `广告ID`,
        SUM(IF(xyz_campaign_id IS NULL, 1, 0))       AS `XYZ公司广告类别ID`,
        SUM(IF(fb_campaign_id IS NULL, 1, 0))        AS `facebook广告活动ID`,
        SUM(IF(age IS NULL, 1, 0))                   AS `年龄`,
        SUM(IF(gender IS NULL, 1, 0))                AS `性别`,
        SUM(IF(interest IS NULL, 1, 0))              AS `兴趣`,
        SUM(IF(Impressions IS NULL, 1, 0))           AS `展示次数`,
        SUM(IF(Clicks IS NULL, 1, 0))                AS `点击次数`,
        SUM(IF(Spent IS NULL, 1, 0))                 AS `XYZ公司广告花费支出`,
        SUM(IF(Total_Conversion IS NULL, 1, 0))      AS `广告带来咨询次数`,
        SUM(IF(Approved_Conversion IS NULL, 1, 0))   AS `广告带来交易次数`
FROM new_advertisement;

-- 4. 删除无用列
ALTER TABLE new_advertisement
DROP column fb_campaign_id;
-- 5. 广告花费和广告销售额
SELECT  xyz_campaign_id                 AS `广告活动`,
        SUM(Spent)                      AS `广告花费`,
        SUM(Approved_conversion) * 100  AS `广告销售额`
FROM new_advertisement
GROUP BY xyz_campaign_id;
-- 6. 点击率, 激活率和转化率
SELECT  xyz_campaign_id                                             AS `广告活动`,
        SUM(Impressions)                                            AS `展示量`,
        SUM(Clicks)                                                 AS `点击量`,
        SUM(Total_Conversion)                                       AS `激活量`,
        SUM(Approved_Conversion)                                    AS `转化量`,
        ROUND(SUM(Clicks) / SUM(Impressions), 2)                    AS `点击率`,
        ROUND(SUM(Total_Conversion) / SUM(Clicks), 2)               AS `激活率`,
        ROUND(SUM(Approved_Conversion) / SUM(Total_Conversion), 2)  AS `转化率`
FROM new_advertisement
GROUP BY xyz_campaign_id;
-- 7. CPC, CPA和ROAS
SELECT  xyz_campaign_id                                          AS `广告活动`,
        COUNT(xyz_campaign_id)                                   AS `广告数量`,
        SUM(Spent)                                               AS `广告花费`,
        SUM(Approved_Conversion) * 100                           AS `广告销售额`,
        ROUND(SUM(spent) / SUM(impressions) * 1000, 2)           AS `CPM`,
        ROUND(SUM(Spent) / SUM(Clicks), 2)                       AS `CPC`,
        ROUND(SUM(Spent) / SUM(Total_Conversion) ,2)             AS `CPA`,
        ROUND(SUM(Approved_Conversion) * 100 / SUM(Spent), 2)    AS `ROI`
FROM new_advertisement
GROUP BY xyz_campaign_id;
-- 8. 年龄和广告
SELECT  xyz_campaign_id                                         AS `广告活动`,
        age                                                     AS `年龄`,
        SUM(Impressions)                                        AS `展示量`,
        SUM(Clicks)                                             AS `点击量`,
        SUM(Total_Conversion)                                   AS `激活量`,
        SUM(Approved_Conversion)                                AS `转化量`,
        ROUND(SUM(Clicks)/SUM(Impressions),6)                   AS `点击率`,
        ROUND(SUM(Total_Conversion)/SUM(Clicks),2)              AS `激活率`,
        ROUND(SUM(Approved_Conversion)/SUM(Total_Conversion),2) AS `转化率`
FROM new_advertisement
GROUP BY xyz_campaign_id,
         age
ORDER BY 点击率 DESC,
         激活率 DESC,
         转化率 DESC;
-- 9. 性别和广告
SELECT  xyz_campaign_id                                         AS `广告活动`,
        gender                                                  AS `性别`,
        SUM(Impressions)                                        AS `展示量`,
        SUM(Clicks)                                             AS `点击量`,
        SUM(Total_Conversion)                                   AS `激活量`,
        SUM(Approved_Conversion)                                AS `转化量`,
        ROUND(SUM(Clicks)/SUM(Impressions),6)                   AS `点击率`,
        ROUND(SUM(Total_Conversion)/SUM(Clicks),2)              AS `激活率`,
        ROUND(SUM(Approved_Conversion)/SUM(Total_Conversion),2) AS `转化率`
FROM new_advertisement
GROUP BY xyz_campaign_id,
         gender
ORDER BY 点击率 DESC,
         激活率 DESC,
         转化率 DESC;
-- 10. 兴趣和广告
SELECT  xyz_campaign_id                                         AS `广告活动`,
        interest                                                AS `兴趣`,
        SUM(Impressions)                                        AS `展示量`,
        SUM(Clicks)                                             AS `点击量`,
        SUM(Total_Conversion)                                   AS `激活量`,
        SUM(Approved_Conversion)                                AS `转化量`,
        ROUND(SUM(Clicks)/SUM(Impressions),6)                   AS `点击率`,
        ROUND(SUM(Total_Conversion)/SUM(Clicks),2)              AS `激活率`,
        ROUND(SUM(Approved_Conversion)/SUM(Total_Conversion),2) AS `转化率`
FROM new_advertisement
GROUP BY xyz_campaign_id,
        interest
ORDER BY 点击率 DESC,
         激活率 DESC,
         转化率 DESC;
/*
1.广告成效方面
由于广告组916展示量等数据量基数太少，需要更多的数据量才能进一步分析。936导入成本最低，ROI最高，是表现最后的广告活动。

建议：
检查916广告展示量并优化
分析1178和936广告活动第一次转化的具体情况，找到为什么点击量大的情况下，转化率低，优化用户转化渠道。
重点优化广告活动1178，降低广告花费占比。
2.定位目标受众方面

广告活动1178：
年龄：最受年龄段30-34的用户群喜爱，此年龄段的的活跃人数占32.16%，虽然点击率是最低的，但是大部分的购买行为都发生在这一群体，转化率占13%。
兴趣：点击率最高的是兴趣编号为64的用户群体，第一次转化率最高的是兴趣编号100的用户群，第二次转化率最高的是用户群体65
性别：男性活跃人数较多；男性的点击率较低，但转化率最高；而女性正好相反
建议：
将男性作为主要投放对象
进一步分析女性转化率低的具体原因，提高女性用户转化率。
可将30-34年龄段作为主要目标受众群体，增加曝光量，优化点击率。
45-49年龄段的用户点击率最高，但是转化率最低，建议检查此环节用户具体行为，并优化。
将最终完成转化最高的用户群体65、19、65、26、64、106、100等为主要的投放群体
检查并优化64、25、23等点击率和第一次转化率靠前，但未能完成最终转化的用户群。

广告活动936：
年龄：最受年龄段30-34的用户群喜爱，此年龄段的的活跃人数占42.24%，与前面1178情况类似点击率最低，但是转化率最高。
兴趣：兴趣编号2的用户群体点击率及第二次转化率最高，兴趣编号24的第一次转化率最高；在这里也能看出这个广告活动投放的目标受众较精准，相比之下，广告成效也是最好的。
性别：女性的活跃人数较多；女性的点击率最高，但是转化率最低。
建议：
男女双方都是主要受众目标
优化男性用户的点击率及分析女性用户转化率低的原因。
可将30-34年龄段作为主要目标受众群体，增加曝光量，优化点击率。
45-49年龄段的用户点击率最高，但是转化率最低，建议检查此环节用户具体行为，并优化。
将最终完成转化最高的用户群体2、24、21、7、30等为主要的投放群体
检查并优化30、25、19等点击率和第一次转化率靠前，但未能完成最终转化的用户群。

广告活动916：
年龄：30-34年龄段人数最多，占53.7%；35-39年龄段的点击率最低，但转化率最高
兴趣：点击率最高的是兴趣编号为21的用户群体，第一次转化率最高的是兴趣编号27的用户群，第二次转化率最高的是用户群体10.；这个广告活动ROI最高，应该是误打误撞的结果，最终转化率最高的10点击率排名最低，而点击率排第三的24，最终转化一次也没有。
建议：
根据此次投放结果，将最终转化最高的10、32、21、27、20作为主要的投放群体
916数据量基数太少，应过段时间再进行投放结果分析。
可将30-34年龄段作为主要目标受众群体，增加曝光量，优化点击率。
45-49年龄段的用户点击率最高，但是转化率最低，建议检查此环节用户具体行为，并优化。
广告活动916也可将35-39年龄段作为主要投放对象。
*/




