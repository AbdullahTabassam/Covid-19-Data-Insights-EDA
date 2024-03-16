-- Question 1:
-- What are the chances of dying if you contract Covid-19 in the UK? (Use TOP(1) for latest date only)

SELECT location, date, total_cases, total_deaths, (CAST(total_deaths AS FLOAT)/CAST(total_cases AS FLOAT))*100 AS DeathPercentage
FROM CovidProject..CovidDeaths
WHERE location LIKE '%kingdom%'
AND continent IS NOT NULL
ORDER BY 1,2 DESC;

-- Question 2:
-- Whaht percentage of population got infected with Covid-19 by far in the UK? (Use TOP(1) for latest date only)

SELECT location, date, Population, total_cases,  (total_cases/population)*100 AS PercentPopulationInfected
FROM CovidProject..CovidDeaths
WHERE location LIKE '%kingdom%'
AND continent IS NOT NULL
ORDER BY 1,2 DESC;

-- Question 3:
-- What percentage of population got infected with Covid-19 in various countries?

SELECT	location, 
		population, 
		MAX(total_cases) AS HighestInfectionCount,  
		MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM CovidProject..CovidDeaths
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC;

-- Question 4:
-- What is the highest death count for various countries? (Uncomment ' AND location like '%kingdom%' ' for UK stats only)

SELECT	location, 
		MAX(Total_deaths) AS TotalDeathCount
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL -- AND location like '%kingdom%'
GROUP BY location
ORDER BY TotalDeathCount DESC;

-- Question 5:
-- What is the total death count so far in each continent?

SELECT	continent, 
		MAX(Total_deaths) as TotalDeathCount
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;

-- Question 6:
-- How may Covid-19 cases and deaths have been reported globally by far? 

Select	SUM(new_cases) AS total_cases, 
		SUM(new_deaths) AS total_deaths, 
		(Sum(CAST(new_deaths AS FLOAT))/SUM(CAST(new_cases AS FLOAT)))*100 AS DeathPercentage
From CovidProject..CovidDeaths
WHERE continent IS NOT NULL;

-- Other way of doing the above querry (using location as World):

SELECT	TOP(1) 
		total_cases, 
		total_deaths,
		(CAST(total_deaths AS FLOAT)/CAST(total_cases AS FLOAT))*100 AS DeathPercentage
FROM CovidProject..CovidDeaths
WHERE location = 'World'
ORDER BY 1 DESC;

-- Question 7:
-- What percentage of people have been administered vaccines in the UK? (Max can be 300% because 1 person can get 3 doses)

-- Using Subquey:

SELECT *, (T.RollingSum/T.population)*100 AS Vaccine_Population_Percentage 
FROM(
	SELECT	dea.continent, 
			dea.location, 
			dea.date, 
			dea.population, 
			vac.new_vaccinations, 
			SUM(vac.new_vaccinations) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingSum
	From CovidProject..CovidDeaths dea
	JOIN CovidProject..CovidVaccinations vac
		ON dea.location = vac.location
		AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL 
)T
WHERE T.location LIKE '%kingdom%'
ORDER BY 7 DESC;

-- Using CTE:

WITH CTE (Continent, Location, Date, Population, New_Vaccinations, RollingSUM)
AS
(
	SELECT	dea.continent, 
			dea.location, 
			dea.date, 
			dea.population, 
			vac.new_vaccinations, 
			SUM(vac.new_vaccinations) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingSum
	From CovidProject..CovidDeaths dea
	JOIN CovidProject..CovidVaccinations vac
		ON dea.location = vac.location
		AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL 
)
SELECT	*, 
		(RollingSum/Population)*100 AS Vaccine_Population_Percentage
From CTE
WHERE location LIKE '%kingdom%'
ORDER BY 7 DESC;

-- Using Temp Tables:

DROP TABLE IF exists #PercentPopVaccinated
CREATE TABLE #PercentPopVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingSum numeric
)

INSERT INTO #PercentPopVaccinated
SELECT	dea.continent, 
		dea.location, 
		dea.date, 
		dea.population, 
		vac.new_vaccinations, 
		SUM(vac.new_vaccinations) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingSum
From CovidProject..CovidDeaths dea
JOIN CovidProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 

SELECT *, (RollingSum/Population)*100 AS Vaccine_Population_Percentage
FROM #PercentPopVaccinated
WHERE Location LIKE '%kingdom%'
ORDER BY 7 DESC;