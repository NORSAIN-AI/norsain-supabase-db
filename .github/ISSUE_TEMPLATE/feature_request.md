name: "Feature request"
description: "Foreslå ny DB-funksjon/policy"
title: "[FEAT] <kort tittel>"
labels: ["enhancement","design-review"]
body:
  - type: textarea
    id: why
    attributes: { label: Hva og hvorfor, placeholder: "Forretningsmål / use case" }
    validations: { required: true }
  - type: dropdown
    id: change_type
    attributes:
      label: Endringstype
      multiple: true
      options: ["Schema (DDL)","Data (DML/seed)","RLS/policy","Function/Trigger","View/MatView","Webhook/Outbox"]
    validations: { required: true }
  - type: textarea
    id: plan
    attributes: { label: Forslag til løsning, render: sql }
