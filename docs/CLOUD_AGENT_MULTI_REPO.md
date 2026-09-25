# Cloud Agent: push na API e no Next (403 cursor[bot])

## Sintoma

```
remote: Permission to jeffinho-ns/giro-certo-api.git denied to cursor[bot].
fatal: unable to access '...': The requested URL returned error: 403
```

O mesmo acontece em `giro-certo-next`. Em `giro-certo-flutter` o push funciona.

## Causa

O Cloud Agent desta sessão usa um ambiente cujo escopo de repos é **só**:

- `github.com/jeffinho-ns/giro-certo-flutter`

O token GitHub gerado (`x-access-token` / `cursor[bot]`) só tem write nesse repo.  
API e Next ficam fora do escopo → GitHub devolve **403**.

Isto **não** é falha de `git commit` local, nem de `.gitignore`.

## Correção (no teu lado — dashboard + GitHub)

### A) Cursor GitHub App com write nos 3 repos

1. https://github.com/settings/installations → instalação **Cursor**
2. Repository access: incluir  
   - `jeffinho-ns/giro-certo-flutter`  
   - `jeffinho-ns/giro-certo-api`  
   - `jeffinho-ns/giro-certo-next`  
   (ou “All repositories”)
3. Contents / Pull requests: **Read and write**
4. Save

### B) Ambiente Cloud **multi-repo**

1. https://cursor.com/dashboard/cloud-agents#environments  
2. Editar (ou criar) o ambiente e selecionar os **3** repositórios acima  
3. Guardar  
4. Arrancar um **novo** Cloud Agent nesse ambiente  

A sessão atual não herda o novo escopo sozinha.

## Depois de corrigir

Num agent novo, pedir por exemplo:

> Faz push do patch de manutenção crítica em giro-certo-api e do perfil admin em giro-certo-next.

Até lá, continua a valer o apply no Mac:

```bash
# API
cd ~/giro-certo-api
bash /caminho/giro-certo-flutter/docs/patches/maintenance-block-admin/aplicar-api.sh

# Next
cd ~/giro-certo-next
bash /caminho/giro-certo-flutter/docs/patches/maintenance-block-admin/aplicar-next.sh
```
