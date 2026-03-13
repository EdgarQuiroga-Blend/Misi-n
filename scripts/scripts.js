  const OPENSEARCH_URL = 'http://localhost:9200';
  const INDEX = 'hotel_assets';
 
  const DEMO_DATA = [
    { nombre:'Hospedaje Premium', tipo_servicio:'hospedaje', aplica_a:['perro','gato'], precio:85000, duracion_horas:24, disponible:true,  descripcion:'Suite individual con cama ortopédica, música relajante y cámara de monitoreo 24/7.', tags:['premium','wifi','camara'], capacidad_max:1 },
    { nombre:'Baño y Grooming Completo', tipo_servicio:'baño', aplica_a:['perro'], precio:55000, duracion_horas:2, disponible:true, descripcion:'Baño con shampoo hipoalergénico, secado, corte de uñas y limpieza de oídos.', tags:['hipoalergenico','corte'], capacidad_max:3 },
    { nombre:'Consulta Veterinaria', tipo_servicio:'veterinaria', aplica_a:['perro','gato'], precio:65000, duracion_horas:1, disponible:true, descripcion:'Revisión general con veterinario certificado. Incluye informe de salud.', tags:['salud','urgencias'], capacidad_max:5 },
    { nombre:'Spa Relajante Felino', tipo_servicio:'spa', aplica_a:['gato'], precio:45000, duracion_horas:1.5, disponible:true, descripcion:'Sesión de aromaterapia, cepillado y masaje relajante especial para gatos.', tags:['premium','spa','aromaterapia'], capacidad_max:2 },
    { nombre:'Guardería Diurna', tipo_servicio:'hospedaje', aplica_a:['perro'], precio:40000, duracion_horas:8, disponible:true, descripcion:'Cuidado durante el día con juegos, paseos y socialización supervisada.', tags:['juegos','paseo','social'], capacidad_max:10 },
    { nombre:'Baño Express Gatos', tipo_servicio:'baño', aplica_a:['gato'], precio:35000, duracion_horas:1, disponible:true, descripcion:'Baño especial con técnica anti-estrés para gatos. Incluye perfume felino.', tags:['express','antistres'], capacidad_max:4 },
    { nombre:'Vacunación y Desparasitación', tipo_servicio:'veterinaria', aplica_a:['perro','gato'], precio:75000, duracion_horas:0.5, disponible:true, descripcion:'Aplicación de vacunas y tratamiento antiparasitario completo.', tags:['vacunas','salud','prevencion'], capacidad_max:8 },
    { nombre:'Hospedaje Económico', tipo_servicio:'hospedaje', aplica_a:['perro','gato'], precio:50000, duracion_horas:24, disponible:true, descripcion:'Espacio cómodo compartido. Incluye 2 comidas diarias y paseo matutino.', tags:['economico','comida'], capacidad_max:6 },
    { nombre:'Masaje Terapéutico', tipo_servicio:'spa', aplica_a:['perro'], precio:60000, duracion_horas:1, disponible:false, descripcion:'Masaje muscular especializado para perros con dolores articulares o estrés.', tags:['terapeutico','premium','salud'], capacidad_max:2 },
    { nombre:'Corte de Pelo Especializado', tipo_servicio:'baño', aplica_a:['perro'], precio:80000, duracion_horas:2.5, disponible:true, descripcion:'Corte para razas con pelo largo. Incluye baño, secado y modelado profesional.', tags:['corte','premium','estilo'], capacidad_max:3 },
  ];
 
  const ICONS  = { hospedaje:'🏠', baño:'🛁', veterinaria:'🩺', spa:'✨' };
  const COLORS = { hospedaje:'#E6F1FB', baño:'#E1F5EE', veterinaria:'#FCEBEB', spa:'#EEEDFE' };
 
  let services = [];
  let filters  = { mascota:'todos', tipo:'todos', precio:500000 };
 
  async function loadFromOpenSearch() {
    try {
      const res = await fetch(`${OPENSEARCH_URL}/${INDEX}/_search`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ size:100, query:{ match_all:{} } })
      });
      if (!res.ok) throw new Error('HTTP ' + res.status);
      const json = await res.json();
      return json.hits.hits.map(h => h._source);
    } catch (e) {
      return null;
    }
  }
 
  async function init() {
    const real = await loadFromOpenSearch();
    const bar  = document.getElementById('conn-bar');
    const txt  = document.getElementById('conn-text');
    if (real && real.length > 0) {
      services = real;
      txt.textContent = `Conectado a OpenSearch · ${OPENSEARCH_URL} · ${real.length} servicios cargados`;
      document.getElementById('status-text').textContent = `${real.length} servicios · live`;
    } else {
      services = DEMO_DATA;
      bar.classList.add('warn');
      txt.textContent = '⚠  OpenSearch no disponible — mostrando datos de demostración';
      document.getElementById('status-text').textContent = `${DEMO_DATA.length} servicios · demo`;
    }
    render();
  }
 
  function setFilter(key, val, el) {
    filters[key] = val;
    el.parentElement.querySelectorAll('.chip').forEach(c => c.classList.remove('active'));
    el.classList.add('active');
    render();
  }
 
  function setPrecio(val) {
    filters.precio = parseInt(val);
    document.getElementById('precio-val').textContent =
      parseInt(val) >= 500000 ? 'Sin límite' : '$' + parseInt(val).toLocaleString('es-CO');
    render();
  }
 
  function render() {
    const filtered = services.filter(s => {
      if (!s.disponible) return false;
      if (filters.mascota !== 'todos' && !(s.aplica_a || []).includes(filters.mascota)) return false;
      if (filters.tipo !== 'todos' && s.tipo_servicio !== filters.tipo) return false;
      if ((s.precio || 0) > filters.precio) return false;
      return true;
    });
 
    document.getElementById('results-count').textContent =
      `${filtered.length} servicio${filtered.length !== 1 ? 's' : ''} encontrado${filtered.length !== 1 ? 's' : ''}`;
 
    const grid  = document.getElementById('grid');
    const empty = document.getElementById('empty');
 
    if (filtered.length === 0) {
      grid.innerHTML = '';
      empty.style.display = 'block';
      return;
    }
    empty.style.display = 'none';
 
    grid.innerHTML = filtered.map((s, i) => {
      const aplica  = (s.aplica_a || []);
      const tags    = (s.tags || []).slice(0, 4);
      const dur     = s.duracion_horas >= 24
        ? `${Math.round(s.duracion_horas / 24)} día(s)`
        : `${s.duracion_horas}h`;
      const isPremium = (s.tags || []).includes('premium');
 
      const badgesHTML = [
        ...aplica.map(a => `<span class="badge badge-${a}">${a === 'perro' ? '🐶 Perro' : '🐱 Gato'}</span>`),
        isPremium ? `<span class="badge badge-premium">Premium</span>` : ''
      ].join('');
 
      const tagsHTML = tags.map(t => `<span class="tag">${t}</span>`).join('');
 
      return `
        <div class="card" onclick='openModal(${i})'>
          <div class="card-top">
            <div class="card-icon" style="background:${COLORS[s.tipo_servicio] || '#F1EFE8'}">
              ${ICONS[s.tipo_servicio] || '⭐'}
            </div>
            <div class="badges">${badgesHTML}</div>
          </div>
          <div class="card-name">${s.nombre}</div>
          <div class="card-tipo">${s.tipo_servicio}</div>
          <div class="card-desc">${s.descripcion || ''}</div>
          <div class="tags">${tagsHTML}</div>
          <div class="card-footer">
            <span class="price">$${(s.precio || 0).toLocaleString('es-CO')}</span>
            <span class="duration">${dur}</span>
          </div>
        </div>`;
    }).join('');
 
    window._filteredServices = filtered;
  }
 
  function openModal(i) {
    const s   = window._filteredServices[i];
    const dur = s.duracion_horas >= 24
      ? `${Math.round(s.duracion_horas / 24)} día(s)`
      : `${s.duracion_horas} hora(s)`;
 
    document.getElementById('modal-content').innerHTML = `
      <div class="modal-header">
        <span class="modal-title">${ICONS[s.tipo_servicio] || '⭐'} ${s.nombre}</span>
        <button class="modal-close" onclick="closeModal()">✕</button>
      </div>
      <p class="modal-desc">${s.descripcion || ''}</p>
      <div class="modal-row"><span class="modal-key">Tipo de servicio</span><span class="modal-val" style="text-transform:capitalize">${s.tipo_servicio}</span></div>
      <div class="modal-row"><span class="modal-key">Aplica para</span><span class="modal-val">${(s.aplica_a || []).join(', ')}</span></div>
      <div class="modal-row"><span class="modal-key">Precio</span><span class="modal-val">$${(s.precio || 0).toLocaleString('es-CO')} COP</span></div>
      <div class="modal-row"><span class="modal-key">Duración</span><span class="modal-val">${dur}</span></div>
      <div class="modal-row"><span class="modal-key">Capacidad máxima</span><span class="modal-val">${s.capacidad_max || 'N/A'} mascotas</span></div>
      <div class="modal-row"><span class="modal-key">Disponibilidad</span>
        <span class="modal-val ${s.disponible ? 'modal-avail-yes' : 'modal-avail-no'}">
          ${s.disponible ? '✓ Disponible' : '✗ No disponible'}
        </span>
      </div>
      <div class="modal-row"><span class="modal-key">Tags</span><span class="modal-val">${(s.tags || []).join(', ') || 'N/A'}</span></div>
      <button class="btn-reservar" onclick="alert('¡Reserva para ${s.nombre} registrada! El equipo HPG se pondrá en contacto contigo.')">
        Reservar este servicio
      </button>
    `;
    document.getElementById('modal-overlay').classList.add('open');
  }
 
  function closeModal() {
    document.getElementById('modal-overlay').classList.remove('open');
  }
 
  function handleOverlayClick(e) {
    if (e.target === document.getElementById('modal-overlay')) closeModal();
  }
 
  document.addEventListener('keydown', e => { if (e.key === 'Escape') closeModal(); });
 
  init();




