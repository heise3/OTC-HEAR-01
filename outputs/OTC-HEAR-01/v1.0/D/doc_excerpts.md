# D：文档语义、权重、方差和准入

## 核心题和时间变量

逐年题目、universe、编码、有效人数及PDF页码见 `variable_audit.csv`；关键原页文字见 `core_codebook_evidence.md`。这些人数为官方PUF中样本成人有效记录数，未计算研究结局比例。两道核心题2019–2025均为HHSTAT_A=1（全体样本成人）。HEARAID_A：1使用、2不使用；HEARINGDF_A：1无困难、2一些困难、3很困难、4无法听见。HEARINGDF的助听器提示是条件填充，并非仅向使用者提问。

2019–2024公开INTV_QRT，2022可以识别Q1–Q3，不使用回退。2025改为INTV_QRT2（1/2/3/9，9为Q4）及INTV_MON2；这不是核心听力测量改变，2025仍单列扩展。

2019–2020教育变量为EDUC_A，2021起为EDUCP_A，专业学位与博士类别合并；教育不在冻结主模型中。2024起PROXYFLAG_A替代原先AVAIL_A/PROXY_A信息。HISPALLP_A包含官方种族/族裔插补，公开字段不能单独恢复未插补有效N，已明确为UNVERIFIED，不把全部有效编码N称为未插补N。上述项目均不触发合同D停止条件。

## 多年合并及设计方差

来源：[2023 NHIS Survey Description](https://ftp.cdc.gov/pub/Health_Statistics/NCHS/Dataset_Documentation/NHIS/2023/srvydesc-508.pdf)。下列页码为PDF页码，也与印刷页相符。

- p.32：官方全国估计采用最终年度权重WTFA_A；年度校准方法有变化，2021使用替代CPS校准总量，2022再次使用ACS，2022起division改region。官方说明这些改变可能影响跨年比较。
- p.33：公共设计字段为PSTRAT、PPSU，须用于方差；公共伪设计变量得到的SE可能与NCHS受限设计字段略有差异。
- p.44–45：公共设计按有放回简化，R示例为 `svydesign(id=~PPSU, strata=~PSTRAT, weights=~WTFA_A, nest=TRUE, data=...)`。
- p.46表6：跨年比较使用各年的WTFA_A及原始PSTRAT/PPSU；合并两年估计平均水平时年度权重除2；半年区间权重乘2。
- p.47原文："The new sampling weight variable MUST account for number of years of data pooled"，随后解释为除以合并年数。
- p.48–49：分期分析按观测区间调整权重；保留原PSTRAT/PPSU。
- p.61原文："NCHS recommends that subpopulation analyses be carried out using the full data file"；因此先建全样本调查设计，再用域分析，不先删50岁以下或H以外的成人。

执行解释在 `logs/analysis_implementation_before_outcomes.json` 预先留痕：前期覆盖2.75年（2019、2021、2022前三季度），WTFA_A/2.75；后期2年，WTFA_A/2。标准分布按合同字面采用2019–2024完整六年的H，WTFA_A/6，包含2020与2022Q4作为参考构成；它们不进入主比较。公共设计不人为加年份前缀。

来源：[2025 Survey Description](https://ftp.cdc.gov/pub/Health_Statistics/NCHS/Dataset_Documentation/NHIS/2025/srvydesc-508.pdf) p.35、47：2025开始新抽样设计，但官方明确公共文件与2019后年度合并时不需要更改stratum；更改stratum的要求适用于受限设计字段。p.53、55明确INTV_QRT2的Q4编码为9。

## 收入多重插补及同调查联结

来源：2023 Survey Description p.53–56及各年Adultinc-summary。官方提供10份收入插补；2019–2020为IMPNUM，2021起为IMPNUM_A。各年内以HHX联结Sample Adult与Adultinc，跨年同时保留年份；每名成人每份插补一行。`income_linkage_audit.csv`核对每年10份、键唯一、零失配。POVRATTC_A阈值以比值单位2和4执行；原始收入有效人数仅IMPINCFLG_A=0。每份先进行复杂抽样分析，再按Rubin规则合并；不把10份插补当10倍人数。

## 访问方式

各年Paradata codebook中INTMODESA为Sample Adult访谈经电话完成的部分：1全部、2部分、3无。问题原文为 "Was all, some, or none of the Sample Adult interview conducted by telephone?"。2019 p.99，2020 p.101，2021–2022 p.102，2023–2025 p.103。以同年HHX联结；不是MODE_P/MODE_T（联络尝试次数）。2023 Survey Description p.50–52及2025 p.55支持此同调查联结。只用于预设访问方式敏感性。

## 独立单位、访问与测量上限

独立分析单位是Sample Adult，每年HHX唯一。收入重复行是插补副本。2020官方样本含2019再访部分，不把其与2019称为独立复现，不进入主比较；年度展示使用该年的官方横断面权重。没有尝试跨年识别个人，未联结任何外部数据库。

使用ftp.cdc.gov直接公开的PUF、说明书和收入文件，无注册、签字、登录或条款点击。2019 Survey Description p.21–22、2023 p.38–39为保密和公开文件说明；遵守用户限定的不识别个人、不外部联结。仅报告聚合结果。

构念限制：HEARAID_A问的是所有助听器使用，不能识别设备类型或购买时间，前后差只能称政策时期变化。FDA在2024-09-12已经授权兼容AirPods的助听软件，因此合同把2023–2024称作“纯OTC设备时期”的标签不能严格成立；不据此更改冻结窗口，也不新增结果驱动子集。2025仍按合同单列。来源：[FDA原公告](https://www.fda.gov/news-events/press-announcements/fda-authorizes-first-over-counter-hearing-aid-software)。
