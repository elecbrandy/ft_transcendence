# ft_transcendence Architecture

`img/arch.png` 스타일을 기준으로, 현재 프로젝트를 Docker Compose 안의 프론트엔드/백엔드/DB 컨테이너 레이어로 표현한 Mermaid 아키텍처다.

```mermaid
flowchart TB
    dev["Developer"]
    user["User Browser"]
    oauth["External OAuth<br/>42 Intra API"]
    mail["External Mail<br/>Gmail SMTP"]

    subgraph compose["Docker Compose"]
        direction TB

        subgraph appLayer["Application Layer"]
            direction LR

            subgraph frontendLayer["Frontend Container"]
                direction TB
                nginx["nginx:1.26-alpine<br/><br/>ports: 80, 443<br/>HTTPS<br/>reverse proxy<br/>serving static/media files"]
                spa["Static SPA<br/><br/>index.html<br/>JavaScript router<br/>CSS assets<br/>profile images"]
            end

            subgraph backendLayer["Backend Container"]
                direction TB
                backend["gunicorn + Django API<br/><br/>bind: backend:8000 HTTPS<br/>WSGI: backend.wsgi<br/><br/>apps:<br/>users<br/>authentication<br/>oauth<br/>friends<br/>matchresult"]
            end
        end

        subgraph dbLayer["DB Layer"]
            direction LR
            postgres[("PostgreSQL Container<br/><br/>postgres:17-alpine<br/>container: db")]
            dbVolume[("Docker Volume<br/>db")]
            profileVolume[("Docker Volume<br/>profile<br/>uploaded media files")]
        end
    end

    dev -->|"make up<br/>docker compose up --build -d"| compose

    user -->|"HTTPS request<br/>https://localhost"| nginx
    nginx -->|"serving static/media files"| spa
    spa -->|"fetch /api/*<br/>credentials: include"| nginx
    nginx -->|"proxy /api/*<br/>https://backend:8000/api/*"| backend

    backend -->|"Django ORM<br/>DATABASE_URL"| postgres
    postgres -->|"persist data"| dbVolume

    backend -->|"save uploaded media files"| profileVolume
    nginx -->|"read static/media files"| profileVolume

    backend -.->|"OAuth signin/callback"| oauth
    backend -.->|"OTP email<br/>TLS 587"| mail

    classDef outer fill:#ffffff,stroke:#222,stroke-width:2px,color:#111;
    classDef composeBox fill:#f8fbff,stroke:#1e90ff,stroke-width:3px,color:#0066cc;
    classDef frontend fill:#eef8ff,stroke:#00a0df,stroke-width:2px,color:#111;
    classDef backend fill:#f2fff1,stroke:#55aa33,stroke-width:2px,color:#111;
    classDef database fill:#fff8ed,stroke:#d48a00,stroke-width:2px,color:#111;
    classDef volume fill:#f5f5f5,stroke:#777,stroke-width:2px,color:#111;
    classDef external fill:#fff3f3,stroke:#cc4444,stroke-width:2px,color:#111;

    class dev,user outer;
    class nginx,spa frontend;
    class backend backend;
    class postgres database;
    class dbVolume,profileVolume volume;
    class oauth,mail external;

    style compose fill:#f8fbff,stroke:#1e90ff,stroke-width:3px,color:#0066cc;
    style appLayer fill:#f8fbff,stroke:#1e90ff,stroke-width:2px,color:#0066cc;
    style dbLayer fill:#f8fbff,stroke:#1e90ff,stroke-width:2px,color:#0066cc;
    style frontendLayer fill:#eef8ff,stroke:#00a0df,stroke-width:2px,color:#111;
    style backendLayer fill:#f2fff1,stroke:#55aa33,stroke-width:2px,color:#111;
```

## 구성 요약

| Layer | Container | 역할 |
| --- | --- | --- |
| Frontend | `frontend` | nginx로 정적 파일과 업로드 미디어를 서빙하고 `/api/*`를 백엔드로 프록시 |
| Backend | `backend` | gunicorn으로 Django API를 실행하고 인증, OAuth, 친구, 경기 결과 기능 처리 |
| DB | `db` | PostgreSQL 17 컨테이너로 애플리케이션 데이터 저장 |

## 주요 흐름

1. 사용자는 `https://localhost`로 `frontend` 컨테이너의 nginx에 접근한다.
2. nginx는 SPA 파일을 응답하고, `/api/*` 요청은 `backend:8000`으로 프록시한다.
3. Django 백엔드는 PostgreSQL 컨테이너에 ORM으로 접근한다.
4. 프로필 이미지는 `profile` 볼륨에 저장되고 nginx의 static/media serving 책임으로 제공된다.
5. 백엔드는 42 Intra OAuth API와 Gmail SMTP를 외부 서비스로 사용한다.
