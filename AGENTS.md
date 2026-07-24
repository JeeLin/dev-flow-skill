# 项目约定

## 技术栈
- 前端：React + TypeScript
- 后端：Node.js + Express
- 数据库：SQLite

## 目录结构
```
src/
  components/    # React 组件
  api/           # API 路由
  db/            # 数据库相关
tests/           # 测试文件
```

## 测试命令
- 单元测试：`npm test`
- 覆盖率：`npm test -- --coverage`

## 审查维度
1. **接口设计**：API 端点是否 RESTful，参数是否合理
2. **数据模型**：数据库表结构是否完整，字段类型是否正确
3. **错误处理**：异常情况是否有合适的错误响应
4. **安全性**：是否有 SQL 注入、XSS 等安全漏洞
5. **代码风格**：是否遵循项目编码规范
