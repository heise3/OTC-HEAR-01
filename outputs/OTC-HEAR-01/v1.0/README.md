# OTC-HEAR-01 v1.0：终局交付包

终局GO；A0至L4全部PASS。主科学结果为全国总体使用的冻结等效成立，见REPORT.md。L4已结束；包内脚本用于复算，不构成继续扩题或改阈值的授权。

先读：REPORT.md → status.json → L2/main_estimate.csv。图形在figures/，提供PDF、SVG、PNG。所有分析表为聚合数据；人数未加权，比例/差值为设计加权估计，SE与CI均按复杂抽样设计计算。L4收入10份插补逐份人数不是10倍样本。

目录与合同一致：contract.md / config.yaml / SHA256SUMS，A0 / D / L0 / L1 / L2 / L3 / L4，scripts / logs，REPORT.md / status.json。额外目录figures/及额外文件ARTIFACT_SHA256SUMS用于图形和交付核验。

冻结：SHA256SUMS仅记录执行前contract.md和config.yaml。ARTIFACT_SHA256SUMS覆盖最终交付文件（不含自身）。原始文件与源数据下载哈希在logs/中；A0/sources提供文献原文核查位置和公开来源哈希。完整检索缓存、下载文档和PUF个体记录留在原工作目录；交付ZIP未包含个体记录或RDS模型缓存。

复算环境：R4.6.1，survey、mitools、data.table、jsonlite（确切版本见logs/R_sessionInfo.txt）；Python3，pandas、pypdf用于文档提取与人数审计。标准库负责下载。无注册、无登录。

ZIP保留outputs/OTC-HEAR-01/v1.0结构。解压到一个工作根目录，在该根目录运行脚本。脚本的根路径由自身位置推导；work/保存下载文件和缓存。若要复算，保留原冻结合同与数据哈希，不修改科学设置。下载来源为NCHS官方公开文件：

```text
python outputs/OTC-HEAR-01/v1.0/scripts/download_docs.py
python outputs/OTC-HEAR-01/v1.0/scripts/extract_docs.py
python outputs/OTC-HEAR-01/v1.0/scripts/download_data.py
python outputs/OTC-HEAR-01/v1.0/scripts/audit_variables.py
python outputs/OTC-HEAR-01/v1.0/scripts/count_L0.py
Rscript outputs/OTC-HEAR-01/v1.0/scripts/calibrate_L1.R
Rscript outputs/OTC-HEAR-01/v1.0/scripts/analyze_L2.R
Rscript outputs/OTC-HEAR-01/v1.0/scripts/analyze_L3.R
Rscript outputs/OTC-HEAR-01/v1.0/scripts/analyze_L4.R
Rscript outputs/OTC-HEAR-01/v1.0/scripts/verify_numeric_results.R
Rscript outputs/OTC-HEAR-01/v1.0/scripts/make_figures.R
```

Python中extract_docs.py需有pypdf，audit/count脚本需有pandas。每个分析脚本检查上一门PASS；停止门一旦触发即停止后续，工程修复在同版本留痕。A0文献判读由执行记录提供，不由统计脚本自动替代。

解压后核验：在outputs/OTC-HEAR-01/v1.0内运行`shasum -a 256 -c SHA256SUMS`及`shasum -a 256 -c ARTIFACT_SHA256SUMS`。数据下载脚本保存当前来源哈希；严格复算时应与logs/data_downloads.json中的本次执行哈希一致，避免官方后续修订导致数据漂移。

主要限制：有限A0检索；问卷不能分离OTC与其他设备或新购买；政策因果归因不可识别；2024已存在耳机式软件授权；种族recode的未插补N不可恢复；标准构成按合同字面固定；次要CI未做多重比较校正。这些限制和执行范围已在REPORT.md说明。
