// URL base de OpenSearch
const OS = 'http://localhost:9200';

// Aquí guardamos todos los datos al cargar
let allPets = [];
let allServices = [];

// Estado actual de filtros
let activeFilter = 'todos';
let searchTerm = '';
let activeTab = 'mascotas';

// ── Al cargar la página, traemos los datos ──
window.addEventListener('DOMContentLoaded', () => {
  fetchPets();
  fetchServices();
});

// ── TRAE MASCOTAS DE OPENSEARCH ──
async function fetchPets() {
  try {
    // Hacemos un POST al endpoint _search de OpenSearch
    // match_all: {} significa "trae todos los documentos"
    const res = await fetch(`${OS}/pets_catalog/_search`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ size: 100, query: { match_all: {} } })
    });
    const data = await res.json();
    // OpenSearch devuelve los docs dentro de data.hits.hits
    // cada hit tiene _source con el documento real
    allPets = data.hits.hits.map(h => h._source);
    renderPets();
  } catch (e) {
    showError('No se pudo conectar con OpenSearch en localhost:9200. Asegúrate de que el stack esté corriendo.');
    document.getElementById('gridMascotas').innerHTML = `<div class="empty">Sin conexión a OpenSearch</div>`;
  }
}

// ── TRAE SERVICIOS DE OPENSEARCH ──
async function fetchServices() {
  try {
    const res = await fetch(`${OS}/hotel_assets/_search`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ size: 100, query: { match_all: {} } })
    });
    const data = await res.json();
    allServices = data.hits.hits.map(h => h._source);
    renderServices();
  } catch (e) {
    document.getElementById('gridServicios').innerHTML = `<div class="empty">Sin conexión a OpenSearch</div>`;
  }
}

// ── RENDERIZA LAS CARDS DE MASCOTAS ──
function renderPets() {
  let list = [...allPets]; // copia del array original

  // Filtrar por búsqueda de texto
  if (searchTerm) {
    const q = searchTerm.toLowerCase();
    list = list.filter(p =>
      p.nombre?.toLowerCase().includes(q) ||
      p.raza?.toLowerCase().includes(q) ||
      p.descripcion?.toLowerCase().includes(q) ||
      (p.temperamento || []).some(t => t.toLowerCase().includes(q))
    );
  }

  // Filtrar por tipo o disponibilidad
  if (activeFilter === 'perro') list = list.filter(p => p.tipo === 'perro');
  else if (activeFilter === 'gato') list = list.filter(p => p.tipo === 'gato');
  else if (activeFilter === 'disponible') list = list.filter(p => p.adoptado === false);

  // Actualizar contador
  document.getElementById('countMascotas').textContent = `${list.length} resultado${list.length !== 1 ? 's' : ''}`;

  // Si no hay resultados
  if (!list.length) {
    document.getElementById('gridMascotas').innerHTML = `<div class="empty">No se encontraron mascotas con ese criterio</div>`;
    return;
  }

  // Generar HTML de cada card con template literals
  document.getElementById('gridMascotas').innerHTML = list.map(p => `
    <div class="card">
      <div class="card-top">
        <div class="avatar ${p.tipo}">${p.tipo === 'perro' ? '🐶' : '🐱'}</div>
        <div>
          <div class="card-name">${p.nombre}</div>
          <div class="card-sub">${p.raza} · ${p.tipo}</div>
        </div>
      </div>
      <div class="card-meta">
        <div class="meta-item">
          <div class="meta-label">Edad</div>
          <div class="meta-value">${p.edad} año${p.edad !== 1 ? 's' : ''}</div>
        </div>
        <div class="meta-item">
          <div class="meta-label">Peso</div>
          <div class="meta-value">${p.peso} kg</div>
        </div>
        <div class="meta-item">
          <div class="meta-label">Sexo</div>
          <div class="meta-value">${p.sexo}</div>
        </div>
        <div class="meta-item">
          <div class="meta-label">Color</div>
          <div class="meta-value">${p.color}</div>
        </div>
      </div>
      ${p.temperamento?.length ? `
        <div class="tags">
          ${p.temperamento.slice(0,4).map(t => `<span class="tag">${t}</span>`).join('')}
        </div>` : ''}
      <div class="card-footer">
        <span class="status-badge ${p.adoptado ? 'adoptado' : 'disponible'}">
          ${p.adoptado ? 'Adoptado' : 'Disponible'}
        </span>
        <span class="fecha">${p.fecha_ingreso}</span>
      </div>
    </div>
  `).join('');
}

// ── RENDERIZA LAS CARDS DE SERVICIOS ──
function renderServices() {
  let list = [...allServices];

  if (searchTerm) {
    const q = searchTerm.toLowerCase();
    list = list.filter(s =>
      s.nombre?.toLowerCase().includes(q) ||
      s.descripcion?.toLowerCase().includes(q) ||
      s.tipo_servicio?.toLowerCase().includes(q) ||
      (s.tags || []).some(t => t.toLowerCase().includes(q))
    );
  }

  if (activeFilter === 'perro') list = list.filter(s => (s.aplica_a || []).includes('perro'));
  else if (activeFilter === 'gato') list = list.filter(s => (s.aplica_a || []).includes('gato'));

  document.getElementById('countServicios').textContent = `${list.length} resultado${list.length !== 1 ? 's' : ''}`;

  if (!list.length) {
    document.getElementById('gridServicios').innerHTML = `<div class="empty">No se encontraron servicios</div>`;
    return;
  }

  document.getElementById('gridServicios').innerHTML = list.map(s => `
    <div class="service-card">
      <div class="service-header">
        <div class="service-name">${s.nombre}</div>
        <div class="price">$${Number(s.precio).toLocaleString('es-CO')}<br><span>COP</span></div>
      </div>
      <div class="service-desc">${s.descripcion}</div>
      <div class="service-meta">
        <span class="service-chip">⏱ ${s.duracion_horas}h</span>
        <span class="service-chip">👥 Máx ${s.capacidad_max}</span>
        ${(s.aplica_a || []).map(a => `<span class="service-chip">${a === 'perro' ? '🐶' : '🐱'} ${a}</span>`).join('')}
      </div>
      <div class="tags">
        ${(s.tags || []).slice(0,4).map(t => `<span class="tag">${t}</span>`).join('')}
      </div>
      <div class="card-footer">
        <span class="status-badge ${s.disponible ? 'disponible' : 'adoptado'}">
          ${s.disponible ? 'Disponible' : 'No disponible'}
        </span>
        <span class="fecha">${s.tipo_servicio}</span>
      </div>
    </div>
  `).join('');
}

// ── CAMBIAR TAB ──
function switchTab(tab, btn) {
  activeTab = tab;
  // Quitar active de todos los botones y ponerlo en el clickeado
  document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
  btn.classList.add('active');
  // Mostrar/ocultar secciones
  document.getElementById('secMascotas').style.display = tab === 'mascotas' ? '' : 'none';
  document.getElementById('secServicios').style.display = tab === 'servicios' ? '' : 'none';
}

// ── CAMBIAR FILTRO ──
function setFilter(f, btn) {
  activeFilter = f;
  document.querySelectorAll('.filter-chip').forEach(b => b.classList.remove('active'));
  btn.classList.add('active');
  renderPets();
  renderServices();
}

// ── BUSCAR ──
function onSearch() {
  searchTerm = document.getElementById('searchInput').value.trim();
  renderPets();
  renderServices();
}

// ── MOSTRAR ERROR ──
function showError(msg) {
  const el = document.getElementById('errorBanner');
  el.textContent = '⚠️ ' + msg;
  el.style.display = 'block';
}
