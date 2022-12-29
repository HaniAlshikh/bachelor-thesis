# Evaluation and use of Event-Sourcing for audit logging

Keeping accurate audit records is a requirement for complaint \gls{ac:it} systems, especially when used in sensitive industries such as government, finance, infrastructure, etc.

Event-Sourced architectures are rapidly gaining in popularity as they provide reliability, flexibility, and scalability. One of the primary benefits of Event-Sourcing is that it provides complete and immutable records of all events and state changes within the system, allowing for efficient and thorough audit logging by design.

The benefits and challenges of Event-Sourcing compared to other approaches were examined and evaluated. A \gls{ac:poc} auditing component and an audit browser were also developed to showcase what to expect in terms of auditing capabilities as well as laying the groundwork for auditing 2.0 integration...