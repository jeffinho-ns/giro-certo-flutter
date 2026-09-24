# Patch API — manutenção + foto da garagem

Corrige no **giro-certo-api** (sem novo build Flutter):

1. Bootstrap de Bike a partir do cadastro delivery (manutenção / mark-done)
2. Placa duplicada (`Bike_plate_key`)
3. **Restaura a foto de capa da garagem** a partir da foto da moto enviada no cadastro (`motoWithPlateData`)

## Aplicar no Mac (Render auto-deploy)

```bash
cd ~/caminho/para/giro-certo-api
curl -fsSL "https://raw.githubusercontent.com/jeffinho-ns/giro-certo-flutter/cursor/patch-maintenance-bootstrap-4e8a/docs/patches/maintenance-bootstrap/aplicar.sh" -o /tmp/aplicar-garagem.sh
bash /tmp/aplicar-garagem.sh
```

Ou, com os ficheiros locais deste patch:

```bash
cd ~/caminho/para/giro-certo-api
git checkout main && git pull origin main
cp /caminho/para/giro-certo-flutter/docs/patches/maintenance-bootstrap/bike-maintenance-bootstrap.service.ts src/services/
cp /caminho/para/giro-certo-flutter/docs/patches/maintenance-bootstrap/bikes.routes.ts src/routes/
git add src/services/bike-maintenance-bootstrap.service.ts src/routes/bikes.routes.ts
git commit -m "fix(maintenance): restaurar foto de capa da garagem no bootstrap"
git push origin main
```

Depois de o Render ficar **Live**, abre a Garagem no app (puxa para atualizar): a capa volta sozinha.
